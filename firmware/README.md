# OpenOmni — Firmware

Sistema de tracking de pies estilo **SlimeVR** adaptado a la treadmill omnidireccional. La treadmill es **pasiva** (no tiene motores); el firmware solo lee sensores y traduce el movimiento de los pies en locomoción para el juego.

## Arquitectura

```
   PIE IZQUIERDO                 PIE DERECHO
 ┌──────────────┐             ┌──────────────┐
 │ ESP32-C3     │             │ ESP32-C3     │
 │ + MPU-9250   │             │ + MPU-9250   │
 │ + FSR talon  │             │ + FSR talon  │
 │ + LiPo       │             │ + LiPo       │
 └──────┬───────┘             └──────┬───────┘
        │  ESP-NOW (2.4GHz, broadcast, 100 Hz)
        └───────────────┬────────────┘
                        ▼
                ┌───────────────┐
                │ HUB ESP32-S3  │  fusiona -> vector de locomocion
                │ USB HID nativo│  "soft decoupling" (rumbo de los pies)
                └───────┬───────┘
                        │ USB  (se ve como MANDO estandar)
                        ▼
                   PC / SteamVR / juego
```

- `foot_tracker/` — firmware del tracker de pie (×2). Driver I2C del IMU + fusión Mahony + detección de zancada + envío ESP-NOW.
- `hub/` — firmware del receptor. Recibe ambos pies, fusiona y **se presenta como un mando USB** (sin instalar drivers en la PC).
- `openomni_protocol.h` — trama compartida (preámbulo `0x55` + seq + CRC16), inspirada en el formato de los Foot Trackers del Omni One.

## ¿Por qué "mando USB" y no un driver propietario?

El hub ESP32-S3 usa USB HID nativo (TinyUSB) y aparece como un **gamepad estándar**. Así:
- **No hay que instalar ningún driver** en Windows/Linux.
- Funciona en **SteamVR** (locomoción por stick), en juegos planos y en cualquier motor.
- El stick izquierdo = vector de caminar; botón 1 = correr.

> Para *soft decoupling* real (caminar hacia un lado mientras miras a otro, como el Omni One) se puede escribir además un **driver OpenVR** que inyecte el vector en el espacio del jugador. Es opcional; el modo mando ya da locomoción omnidireccional relativa al cuerpo.

## Hardware y cableado (drivers de sensores)

### Tracker de pie (×2) — ESP32-C3
| Señal | Pin ESP32-C3 | A |
|---|---|---|
| I2C SDA | GPIO8 | MPU-9250 SDA |
| I2C SCL | GPIO9 | MPU-9250 SCL |
| FSR (ADC) | GPIO3 | divisor FSR↔10 kΩ a GND |
| LED estado | GPIO10 | LED + R330 a GND |
| VBAT (ADC) | GPIO2 | divisor 1:1 de la LiPo |
| 3V3 / GND | — | alimentación IMU y FSR |

**FSR (sensor de pisada):** `3V3 —[FSR]— A0 —[10kΩ]— GND`. Al pisar baja la resistencia → sube el ADC. Umbral en el código: `fsr > 400` (ajústalo).

**IMU:** el driver I2C está incluido en `foot_tracker.ino` (no usa librería externa). Detecta MPU-9250 (`WHO_AM_I=0x71`), MPU-6500 (`0x70`) o MPU-9255 (`0x73`). Config: accel ±4 g, gyro ±500 dps, DLPF 41 Hz, 200 Hz.
> Nota: la fusión es de **6 ejes** (accel+gyro). Es robusta para el rumbo a corto plazo de cada zancada. Si tu IMU trae magnetómetro (AK8963 en el MPU-9250, o un ICM-20948), puedes añadir su lectura para rumbo **absoluto** sin deriva — marcado en el código dónde iría.

### Hub — ESP32-S3
- Solo USB al PC. Botón **BOOT (GPIO0)** = recalibrar "adelante".
- (Opcional) OLED SSD1306 por I2C para ver estado/batería.

## Librerías necesarias

Todas vienen con el **core arduino-esp32 (v3.x)** — no hay que instalar terceros:
- `Wire`, `WiFi`, `esp_now` (ambos sketches)
- `USB`, `USBHIDGamepad` (solo el hub, requiere ESP32-S3)

Instala el core desde el Boards Manager de Arduino IDE: *"esp32 by Espressif"* (≥3.0.0).

## Flashear

### Trackers de pie
1. Abre `foot_tracker/foot_tracker.ino`.
2. En **un** tracker deja `#define THIS_FOOT FOOT_LEFT`; en el otro cámbialo a `FOOT_RIGHT`.
3. Placa: *ESP32C3 Dev Module*. Sube.

### Hub
1. Abre `hub/hub.ino`.
2. Placa: *ESP32S3 Dev Module*. En **Tools → USB Mode** elige **"USB-OTG (TinyUSB)"** y **USB CDC On Boot: Enabled**.
3. Sube. Al reconectar, el PC lo detecta como **mando**.

> Con `arduino-cli` (si lo instalas):
> ```bash
> arduino-cli compile -b esp32:esp32:esp32c3 firmware/foot_tracker
> arduino-cli compile -b esp32:esp32:esp32s3 firmware/hub
> ```

## Uso / calibración

1. Enciende los dos trackers (LED **verde fijo** = IMU OK; parpadeo rápido = fallo IMU).
2. Conecta el hub al PC.
3. Párate en el cuenco mirando al frente, pon los pies rectos y **mantén BOOT** ~0.3 s para fijar el "adelante".
4. Camina: deslizar el pie hacia atrás en el cuenco = avanzar; la velocidad escala con lo rápido que deslizas. Correr fuerte activa el botón "sprint".
5. En SteamVR/juego, asigna locomoción al **stick izquierdo** del mando nuevo.

## Algoritmo (resumen)

Por pie, cada 10 ms:
1. Mahony → cuaternión → **yaw** (rumbo) y matriz de rotación.
2. Acel. body → mundo, resta 1 g → aceleración lineal.
3. Integra a velocidad; **ZUPT** (zero-velocity update) cuando el FSR marca contacto y la aceleración es baja → mata la deriva.
4. Proyecta la velocidad sobre el rumbo del pie → **velocidad de deslizamiento hacia atrás** = caminar.

El hub toma el pie de apoyo activo (en contacto y más rápido), aplica zona muerta + suavizado, resta el rumbo calibrado (**desacople**) y saca `X=strafe`, `Y=adelante` al stick.

## Opción sin ESP32-S3: puente por Serial

Si no consigues un ESP32-S3, usa un ESP32 normal como hub por **USB serie** y el script `pc_bridge.py` crea el mando virtual en la PC (Windows con `vgamepad`, Linux con `python-uinput`). Ver cabecera del script.
