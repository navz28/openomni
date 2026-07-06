// ============================================================
//  OpenOmni - Protocolo de radio pie -> hub (ESP-NOW)
//  Formato de trama inspirado en el descrito para los Foot
//  Trackers del Omni One: preambulo 0x55 + seq + payload.
//  Copiar identico en foot_tracker.ino y hub.ino.
// ============================================================
#ifndef OPENOMNI_PROTOCOL_H
#define OPENOMNI_PROTOCOL_H
#include <stdint.h>

#define OO_PREAMBLE   0x55
#define OO_VERSION    1

// Identificador de pie
enum FootId : uint8_t { FOOT_LEFT = 0, FOOT_RIGHT = 1 };

// Trama que envia cada tracker de pie (packed => mismo layout en ambos MCUs)
typedef struct __attribute__((packed)) {
    uint8_t  preamble;   // 0x55
    uint8_t  version;    // OO_VERSION
    uint8_t  foot;       // FootId
    uint8_t  seq;        // contador de secuencia (detecta perdida de paquetes)
    float    heading;    // rumbo del pie (yaw) en grados [-180,180]
    float    speed;      // velocidad de deslizamiento hacia atras (m/s), >=0
    uint8_t  contact;    // 1 = pie en el cuenco (FSR), 0 = en el aire
    uint8_t  battery;    // % bateria (0..100)
    uint16_t crc;        // CRC16 de los bytes previos
} FootPacket;

// CRC16-CCITT (poly 0x1021) - valida integridad de la trama
static inline uint16_t oo_crc16(const uint8_t *data, uint16_t len) {
    uint16_t crc = 0xFFFF;
    for (uint16_t i = 0; i < len; i++) {
        crc ^= (uint16_t)data[i] << 8;
        for (uint8_t b = 0; b < 8; b++)
            crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : (crc << 1);
    }
    return crc;
}

#endif // OPENOMNI_PROTOCOL_H
