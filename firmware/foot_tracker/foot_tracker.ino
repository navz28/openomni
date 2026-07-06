// ============================================================
//  OpenOmni - FOOT TRACKER  (uno por pie)
//  MCU : ESP32 / ESP32-C3
//  IMU : MPU-9250 / MPU-6500 (I2C)   +  FSR de talon (ADC)
//  Salida: trama FootPacket por ESP-NOW (broadcast) al hub
//
//  Que hace:
//   1) Lee el IMU (driver I2C minimo, sin librerias externas)
//   2) Fusiona a orientacion con filtro Mahony (6 ejes)
//   3) Detecta contacto (FSR) e integra la velocidad del pie
//      con ZUPT (zero-velocity update) para matar la deriva
//   4) Calcula la velocidad de deslizamiento HACIA ATRAS y el
//      rumbo del pie -> los envia al hub
//
//  Librerias Arduino usadas: Wire, WiFi, esp_now  (todas de serie
//  en el core arduino-esp32). NO requiere libs de terceros.
// ============================================================
#include <Wire.h>
#include <WiFi.h>
#include <esp_now.h>
#include "openomni_protocol.h"

// ---------- CONFIGURA ESTO ----------
#define THIS_FOOT     FOOT_LEFT     // FOOT_LEFT en un tracker, FOOT_RIGHT en el otro
#define PIN_SDA       8
#define PIN_SCL       9
#define PIN_FSR       3             // ADC del sensor de presion de talon
#define PIN_LED       10            // LED de estado
#define PIN_VBAT      2             // ADC divisor de bateria (opcional)
#define MPU_ADDR      0x68          // 0x68 (AD0=GND) o 0x69

// ---------- Registros MPU-9250/6500 ----------
#define REG_WHOAMI    0x75
#define REG_PWR1      0x6B
#define REG_SMPLRT    0x19
#define REG_CONFIG    0x1A
#define REG_GYRO_CFG  0x1B
#define REG_ACC_CFG   0x1C
#define REG_ACC_CFG2  0x1D
#define REG_ACCEL_XH  0x3B

// Escalas elegidas: accel +/-4g (8192 LSB/g), gyro +/-500dps (65.5 LSB/dps)
const float ACC_LSB = 8192.0f;
const float GYR_LSB = 65.5f;
const float G       = 9.80665f;

// ---------- Estado de fusion Mahony ----------
float q0=1, q1=0, q2=0, q3=0;
const float twoKp = 2.0f * 0.9f;   // ganancia proporcional
const float twoKi = 2.0f * 0.01f;  // ganancia integral
float integralFBx=0, integralFBy=0, integralFBz=0;

// ---------- Estado de locomocion ----------
float velX=0, velY=0;              // velocidad horizontal del pie en el mundo (m/s)
uint32_t lastZupt=0;
uint8_t  seq=0;

// ---------- Peer ESP-NOW (broadcast: sin necesidad de MAC) ----------
uint8_t peerBcast[6] = {0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};

// ------------------------------------------------------------
//  Driver I2C minimo del IMU
// ------------------------------------------------------------
void wr(uint8_t reg, uint8_t val){ Wire.beginTransmission(MPU_ADDR); Wire.write(reg); Wire.write(val); Wire.endTransmission(); }
uint8_t rd(uint8_t reg){ Wire.beginTransmission(MPU_ADDR); Wire.write(reg); Wire.endTransmission(false);
                         Wire.requestFrom(MPU_ADDR,1); return Wire.read(); }

bool imuInit(){
    uint8_t who = rd(REG_WHOAMI);          // 0x71 MPU9250, 0x70 MPU6500, 0x73 MPU9255
    if (who!=0x71 && who!=0x70 && who!=0x73) return false;
    wr(REG_PWR1, 0x00);  delay(10);        // despierta
    wr(REG_PWR1, 0x01);  delay(10);        // reloj PLL del gyro
    wr(REG_CONFIG,   0x03);                // DLPF 41 Hz
    wr(REG_SMPLRT,   0x04);                // 200 Hz (1kHz/(1+4))
    wr(REG_GYRO_CFG, 0x08);                // +/-500 dps
    wr(REG_ACC_CFG,  0x08);                // +/-4 g
    wr(REG_ACC_CFG2, 0x03);                // accel DLPF 41 Hz
    delay(10);
    return true;
}

// Lee accel (g) y gyro (rad/s)
void imuRead(float &ax,float &ay,float &az,float &gx,float &gy,float &gz){
    Wire.beginTransmission(MPU_ADDR); Wire.write(REG_ACCEL_XH); Wire.endTransmission(false);
    Wire.requestFrom(MPU_ADDR,14);
    int16_t axr=(Wire.read()<<8)|Wire.read();
    int16_t ayr=(Wire.read()<<8)|Wire.read();
    int16_t azr=(Wire.read()<<8)|Wire.read();
    Wire.read(); Wire.read();               // descarta temperatura
    int16_t gxr=(Wire.read()<<8)|Wire.read();
    int16_t gyr=(Wire.read()<<8)|Wire.read();
    int16_t gzr=(Wire.read()<<8)|Wire.read();
    ax=axr/ACC_LSB; ay=ayr/ACC_LSB; az=azr/ACC_LSB;
    gx=(gxr/GYR_LSB)*DEG_TO_RAD; gy=(gyr/GYR_LSB)*DEG_TO_RAD; gz=(gzr/GYR_LSB)*DEG_TO_RAD;
}

// ------------------------------------------------------------
//  Filtro Mahony AHRS (6 ejes: accel + gyro)
// ------------------------------------------------------------
void mahonyUpdate(float gx,float gy,float gz,float ax,float ay,float az,float dt){
    float recipNorm;
    float halfvx,halfvy,halfvz;
    float halfex,halfey,halfez;

    if(!(ax==0 && ay==0 && az==0)){
        recipNorm = 1.0f/sqrtf(ax*ax+ay*ay+az*az); ax*=recipNorm; ay*=recipNorm; az*=recipNorm;
        // gravedad estimada desde el quaternion
        halfvx = q1*q3 - q0*q2;
        halfvy = q0*q1 + q2*q3;
        halfvz = q0*q0 - 0.5f + q3*q3;
        // error = producto cruz medido x estimado
        halfex = (ay*halfvz - az*halfvy);
        halfey = (az*halfvx - ax*halfvz);
        halfez = (ax*halfvy - ay*halfvx);
        if(twoKi>0.0f){
            integralFBx += twoKi*halfex*dt; integralFBy += twoKi*halfey*dt; integralFBz += twoKi*halfez*dt;
            gx += integralFBx; gy += integralFBy; gz += integralFBz;
        }
        gx += twoKp*halfex; gy += twoKp*halfey; gz += twoKp*halfez;
    }
    // integra el rate de giro
    gx*=0.5f*dt; gy*=0.5f*dt; gz*=0.5f*dt;
    float qa=q0, qb=q1, qc=q2;
    q0 += (-qb*gx - qc*gy - q3*gz);
    q1 += ( qa*gx + qc*gz - q3*gy);
    q2 += ( qa*gy - qb*gz + q3*gx);
    q3 += ( qa*gz + qb*gy - qc*gx);
    recipNorm = 1.0f/sqrtf(q0*q0+q1*q1+q2*q2+q3*q3);
    q0*=recipNorm; q1*=recipNorm; q2*=recipNorm; q3*=recipNorm;
}

float yawDeg(){ return atan2f(2.0f*(q0*q3+q1*q2), 1.0f-2.0f*(q2*q2+q3*q3)) * RAD_TO_DEG; }

// Acelera el vector body -> mundo (solo lo que necesitamos: componentes horizontales)
void bodyAccelToWorld(float ax,float ay,float az,float &wx,float &wy,float &wz){
    // R * a  (R = matriz de rotacion del quaternion)
    wx = (1-2*(q2*q2+q3*q3))*ax + 2*(q1*q2-q0*q3)*ay + 2*(q1*q3+q0*q2)*az;
    wy = 2*(q1*q2+q0*q3)*ax + (1-2*(q1*q1+q3*q3))*ay + 2*(q2*q3-q0*q1)*az;
    wz = 2*(q1*q3-q0*q2)*ax + 2*(q2*q3+q0*q1)*ay + (1-2*(q1*q1+q2*q2))*az;
}

// ------------------------------------------------------------
uint8_t readBattery(){
    int raw = analogRead(PIN_VBAT);
    float v = (raw/4095.0f)*3.3f*2.0f;      // divisor 1:1
    int pct = (int)((v-3.3f)/(4.2f-3.3f)*100.0f);
    return constrain(pct,0,100);
}

void sendPacket(float heading,float speed,uint8_t contact){
    FootPacket p;
    p.preamble=OO_PREAMBLE; p.version=OO_VERSION; p.foot=THIS_FOOT; p.seq=seq++;
    p.heading=heading; p.speed=speed; p.contact=contact; p.battery=readBattery();
    p.crc=oo_crc16((uint8_t*)&p, sizeof(FootPacket)-sizeof(uint16_t));
    esp_now_send(peerBcast, (uint8_t*)&p, sizeof(p));
}

// ------------------------------------------------------------
void setup(){
    Serial.begin(115200);
    pinMode(PIN_LED, OUTPUT);
    analogReadResolution(12);
    Wire.begin(PIN_SDA, PIN_SCL, 400000);

    if(!imuInit()){ // LED parpadeo rapido = fallo de IMU
        while(1){ digitalWrite(PIN_LED,!digitalRead(PIN_LED)); delay(80); }
    }

    WiFi.mode(WIFI_STA);
    if(esp_now_init()!=ESP_OK){ Serial.println("ESP-NOW fail"); ESP.restart(); }
    esp_now_peer_info_t peer={}; memcpy(peer.peer_addr,peerBcast,6);
    peer.channel=0; peer.encrypt=false; esp_now_add_peer(&peer);

    digitalWrite(PIN_LED, HIGH); // verde fijo = OK (como el Omni One)
    lastZupt=millis();
}

uint32_t lastMicros=0, lastTx=0;

void loop(){
    // dt real
    uint32_t now=micros();
    float dt=(lastMicros==0)?0.005f:(now-lastMicros)*1e-6f; lastMicros=now;
    if(dt<=0 || dt>0.1f) dt=0.005f;

    float ax,ay,az,gx,gy,gz;
    imuRead(ax,ay,az,gx,gy,gz);
    mahonyUpdate(gx,gy,gz,ax,ay,az,dt);

    // aceleracion lineal en el mundo (quita la gravedad)
    float wx,wy,wz; bodyAccelToWorld(ax,ay,az,wx,wy,wz);
    wx*=G; wy*=G; wz=(wz-1.0f)*G;               // resta 1g en Z-mundo
    float amag=sqrtf(wx*wx+wy*wy);

    // FSR: contacto con el cuenco
    int fsr=analogRead(PIN_FSR);
    bool contact = fsr > 400;                    // umbral ~ ajustar

    // Integra velocidad horizontal
    velX += wx*dt; velY += wy*dt;

    // ZUPT: si hay contacto y casi no hay aceleracion, el pie esta quieto -> resetea deriva
    if(contact && amag < 0.6f){
        if(millis()-lastZupt > 40){ velX*=0.5f; velY*=0.5f; }  // decaimiento suave
    } else { lastZupt=millis(); }
    // fuga lenta para evitar runaway si se pierde el ZUPT
    velX*=0.995f; velY*=0.995f;

    // Rumbo del pie y velocidad de deslizamiento HACIA ATRAS
    float yaw=yawDeg();
    float fwdx=cosf(yaw*DEG_TO_RAD), fwdy=sinf(yaw*DEG_TO_RAD);
    float vForward = velX*fwdx + velY*fwdy;      // + = adelante, - = atras
    float backSpeed = (vForward < 0) ? -vForward : 0.0f;  // el deslizamiento hacia atras = caminar
    backSpeed = constrain(backSpeed, 0.0f, 3.5f);

    // Envia a 100 Hz
    if(millis()-lastTx >= 10){
        lastTx=millis();
        sendPacket(yaw, contact?backSpeed:0.0f, contact?1:0);
    }
}
