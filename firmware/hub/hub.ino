// ============================================================
//  OpenOmni - HUB receptor / puente a la PC
//  MCU : ESP32-S3  (USB nativo -> se presenta como MANDO USB HID)
//
//  Que hace:
//   1) Recibe las tramas FootPacket de ambos pies por ESP-NOW
//   2) Valida CRC y descarta pies "en el aire"
//   3) Fusiona a un vector de locomocion 2D (magnitud=velocidad,
//      direccion=rumbo del pie)  -> "soft decoupling": el rumbo
//      viene de los PIES, no de la cabeza
//   4) Lo emite como stick izquierdo de un gamepad USB estandar
//      => funciona con SteamVR y con cualquier juego, SIN driver
//
//  Boton BOOT (GPIO0): recalibra el "adelante" al rumbo actual.
//
//  Requiere: arduino-esp32 core 3.x, placa ESP32-S3, USB Mode =
//  "USB-OTG (TinyUSB)".  Librerias USB/USBHIDGamepad de serie.
// ============================================================
#include <WiFi.h>
#include <esp_now.h>
#include "openomni_protocol.h"

// 1 = ESP32-S3, salida como MANDO USB HID (sin driver en PC)
// 0 = ESP32 normal, saca "LOC x y run" por Serial -> usa pc_bridge.py
#define USE_USB_HID 1

#if USE_USB_HID
  #include "USB.h"
  #include "USBHIDGamepad.h"
  USBHIDGamepad gamepad;
#endif

// ---------- Parametros de locomocion ----------
const float MAX_SPEED   = 2.8f;   // m/s que mapea a stick full
const float DEADZONE    = 0.12f;  // m/s por debajo = quieto
const float RUN_THRESH  = 1.6f;   // m/s -> pulsa boton "correr"
const uint32_t TIMEOUT_MS = 200;  // sin datos -> stick a cero
#define PIN_CALIB 0               // boton BOOT

// ---------- Estado por pie ----------
struct FootState { float heading; float speed; bool contact; uint32_t t; uint8_t lastSeq; };
volatile FootState feet[2] = {{0,0,false,0,0},{0,0,false,0,0}};

float forwardRef = 0.0f;          // rumbo considerado "adelante" (calibrable)
float smX=0, smY=0;               // stick suavizado

// ---------- Callback de recepcion ESP-NOW (core 3.x) ----------
void onRecv(const esp_now_recv_info_t *info, const uint8_t *data, int len){
    if(len != sizeof(FootPacket)) return;
    FootPacket p; memcpy(&p, data, sizeof(p));
    if(p.preamble!=OO_PREAMBLE || p.version!=OO_VERSION) return;
    uint16_t crc = oo_crc16((uint8_t*)&p, sizeof(FootPacket)-sizeof(uint16_t));
    if(crc != p.crc) return;                     // trama corrupta
    if(p.foot>1) return;
    feet[p.foot].heading = p.heading;
    feet[p.foot].speed   = p.speed;
    feet[p.foot].contact = p.contact;
    feet[p.foot].t       = millis();
    feet[p.foot].lastSeq = p.seq;
}

void setup(){
    Serial.begin(115200);
    pinMode(PIN_CALIB, INPUT_PULLUP);

#if USE_USB_HID
    gamepad.begin();
    USB.begin();
#endif

    WiFi.mode(WIFI_STA);
    if(esp_now_init()!=ESP_OK){ Serial.println("ESP-NOW fail"); ESP.restart(); }
    esp_now_register_recv_cb(onRecv);
    Serial.println("OpenOmni hub listo (mando USB)");
}

// Elige el pie "activo" = en contacto y mas rapido (pie de apoyo que desliza)
int activeFoot(){
    uint32_t now=millis();
    bool l = feet[0].contact && (now-feet[0].t < TIMEOUT_MS);
    bool r = feet[1].contact && (now-feet[1].t < TIMEOUT_MS);
    if(l && r) return (feet[0].speed >= feet[1].speed) ? 0 : 1;
    if(l) return 0;
    if(r) return 1;
    return -1;
}

int8_t clamp127(float v){ if(v>127)v=127; if(v<-127)v=-127; return (int8_t)v; }

void loop(){
    // recalibracion del "adelante"
    static uint32_t calibHold=0;
    if(digitalRead(PIN_CALIB)==LOW){
        if(calibHold==0) calibHold=millis();
        if(millis()-calibHold>300){
            int f=activeFoot(); if(f<0) f=0;
            forwardRef = feet[f].heading;
            Serial.printf("Calibrado adelante = %.1f deg\n", forwardRef);
            calibHold=0; delay(200);
        }
    } else calibHold=0;

    // vector de locomocion
    float tx=0, ty=0; bool running=false;
    int f=activeFoot();
    if(f>=0){
        float speed=feet[f].speed;
        if(speed>DEADZONE){
            float m = constrain(speed/MAX_SPEED, 0.0f, 1.0f);
            float off = (feet[f].heading - forwardRef) * DEG_TO_RAD;  // desacople de rumbo
            // adelante = -Y (arriba del stick), strafe = X
            tx =  sinf(off) * m;
            ty = -cosf(off) * m;
            running = speed > RUN_THRESH;
        }
    }

    // suavizado (lowpass) para quitar el temblor de la zancada
    smX += (tx - smX)*0.35f;
    smY += (ty - smY)*0.35f;

    int8_t gx = clamp127(smX*127.0f);
    int8_t gy = clamp127(smY*127.0f);
    uint16_t buttons = running ? 0x0001 : 0x0000;   // boton 1 = correr/sprint

#if USE_USB_HID
    // send(x, y, z, rz, rx, ry, hat, buttons) - solo usamos stick izq + boton
    gamepad.send(gx, gy, 0, 0, 0, 0, 0, buttons);
    // telemetria opcional
    static uint32_t dbg=0;
    if(millis()-dbg>250){ dbg=millis();
        Serial.printf("foot=%d X=%d Y=%d run=%d\n", f, gx, gy, running);
    }
#else
    // Modo Serial para pc_bridge.py: linea "LOC <x> <y> <run>" (x,y en -127..127)
    Serial.printf("LOC %d %d %d\n", gx, gy, running?1:0);
#endif
    delay(5);   // ~200 Hz
}
