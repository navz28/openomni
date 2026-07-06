# OpenOmni — Lista de Componentes (BOM)

**Proyecto:** Treadmill omnidireccional pasiva DIY, inspirada en el Virtuix Omni One.
**Principio:** cuenco cóncavo de baja fricción + calzado deslizante + brazo posterior articulado con arnés (sin motores para la locomoción — todo pasivo, la gravedad recentra el pie). Tracking de pies por IMU (estilo SlimeVR) traducido a un mando USB.

**Objetivo dimensional (copiado del Omni One):**
- Diámetro útil del cuenco: **1.20 m**
- Huella total: ~1.20 × 1.50 m
- Carga dinámica de diseño: **hasta 113 kg** de usuario
- Altura de usuario: 1.32–1.92 m

**Filosofía de materiales:** madera (contrachapado + tablero), tubo de PVC, perfil de fierro/acero, rodamientos y piezas rescatadas de **bicicleta**, un **resorte de gas** (hidroneumático) tipo silla de oficina, y piezas **impresas en 3D** para las juntas, carcasas y el calzado.

> Los precios son órdenes de magnitud en USD (mercado general). Casi todo puede abaratarse comprando de segunda mano, rescatando de una bici vieja o sustituyendo por chatarra local. La estimación total DIY ronda **US$180–350** frente a los **US$2,600–3,500** del Omni One.

---

## A. Cuenco cóncavo de baja fricción (la "base")

El corazón mecánico. Perfil parabólico (z = k·r²), radio 600 mm, pendiente en el borde ≈ 13° (rango DIY probado 13–15°). Construcción de **costillas radiales de contrachapado** + piel flexible + superficie deslizante.

| # | Componente | Material / Especificación | Cant. | Costo aprox. |
|---|-----------|---------------------------|-------|-------------|
| A1 | Costillas radiales del cuenco | Contrachapado 15–18 mm, cortadas al perfil parabólico (patrón desde el .scad) | **16** (ver §8 fuerzas) | US$28 |
| A2 | Anillo/aro de borde | Contrachapado 18 mm en segmentos, Ø ext. 1.30 m | 1 juego | US$15 |
| A3 | Cubo central (hub del piso) | Disco de contrachapado 18 mm laminado ×3 (54 mm) | 1 | US$5 |
| A4 | Piel del cuenco (skin) | Contrachapado flexible 3–4 mm (luan/doorskin) o hardboard/masonite, cara lisa | 2–3 hojas | US$25 |
| A5 | **Superficie deslizante** (la que toca el pie) | Opción económica: hardboard sellado con poliuretano + spray de silicona. Opción premium: lámina **HDPE/UHMW 2 mm** o vinílico liso | según opción | US$0–40 |
| A6 | Cola + grapas + tornillos para laminar la piel | Cola de carpintero D3, tornillos 4×20 mm | — | US$10 |
| A7 | Pies antideslizantes / niveladores | Tacos de goma o niveladores M8 | 4–6 | US$8 |

**Subtotal A ≈ US$90–110**

> Alternativa ultra-barata (probada en builds Hackaday/Instructables): forrar el cuenco con **alfombra de pelo corto** y usar **deslizadores de muebles (furniture sliders)** de PTFE en el calzado. Invierte la lógica (alfombra fija + PTFE en el pie) y cuesta ~US$20. Menos duradero pero funcional.

---

## B. Estructura de soporte y base

Aro estructural que sostiene el cuenco a ras de piso y el poste posterior del brazo. Zona del poste = **acero** (soporta el momento del brazo); resto puede ser madera o PVC.

| # | Componente | Material / Especificación | Cant. | Costo aprox. |
|---|-----------|---------------------------|-------|-------------|
| B1 | Marco perimetral inferior | Tubo cuadrado acero 40×40×2 mm **o** viga de pino 45×90 mm | ~5 m | US$30 |
| B2 | **Poste posterior** (mástil del hub) | Tubo cuadrado acero **50×50×3 mm**, alto ~0.35 m sobre el aro | 1 | US$15 |
| B3 | Placa base del poste + cartelas | Platina acero 6 mm + escuadras soldadas/atornilladas | 1 juego | US$12 |
| B4 | Travesaños / refuerzos | Tubo PVC 40 mm (no estructural) o pino | ~3 m | US$10 |
| B5 | Ruedas de traslado (retráctiles) | 2 ruedas industriales 75 mm en el borde trasero (para inclinar y mover) | 2 | US$10 |
| B6 | Tornillería estructural | Pernos M8/M10, tuercas, arandelas, tirafondos | lote | US$15 |
| B7 | **Lastre anti-vuelco** (¡crítico!) | 25–30 kg: arena en cajones del marco, bloques de concreto o pavers, en la mitad trasera (ver §6 fuerzas) | — | US$5 |

**Subtotal B ≈ US$90**

---

## C. Brazo articulado + hub rotatorio + arnés (el "soporte corporal")

Réplica funcional del brazo posterior del Omni One: gira 360° en un hub sobre rodamiento, con dos eslabones y juntas abisagradas (eje horizontal para giro, eje vertical + resorte de gas para agacharse/saltar), rematado en un chaleco/arnés.

| # | Componente | Material / Especificación | Cant. | Costo aprox. |
|---|-----------|---------------------------|-------|-------------|
| C1 | **Rodamiento del hub (giro 360°)** | *Bici:* cazoletas de **pedalier (bottom bracket)** o **buje de rueda** reutilizado; *o* rodamiento tipo **lazy-susan** 150 mm; *o* rodamiento cónico 6008 | 1 | US$8–20 |
| C2 | Eje / husillo del hub | Eje de pedalier de bici **o** perno M16 rectificado + tuercas de leva | 1 | US$8 |
| C3 | Eslabón inferior del brazo | Tubo acero **40×40×3 mm** (M=610 N·m, ver §3 fuerzas), ~0.6 m | 1 | US$12 |
| C4 | Eslabón superior del brazo | Igual, ~0.5 m | 1 | US$8 |
| C5 | **Juntas abisagradas** (2 ejes) | *Bici:* rodamientos de **suspensión/dirección (headset)**; *o* rodamientos 6001 + eje M12; **abrazaderas impresas en 3D** para unir tubos | 2–3 | US$15 |
| C6 | **Resorte de gas (soporte vertical)** | Cilindro **hidroneumático de silla de oficina** (~US$10) *o* amortiguador de portón trasero de auto ~150–250 N; permite agacharse y devuelve suave | 1 | US$10–18 |
| C7 | Tuerca de leva / quick-release | Palanca de **cierre rápido de bici (QR)** para bloquear altura/ángulo del brazo | 1–2 | US$6 |
| C8 | **Chaleco / arnés** | Arnés de escalada acolchado *o* cinturón lumbar de halterofilia + tirantes; placa de anclaje impresa en 3D al brazo | 1 | US$25 |
| C9 | Rótula de conexión brazo↔chaleco | Rótula de dirección de auto (rótula de suspensión) pequeña o junta universal impresa reforzada | 1 | US$10 |
| C10 | Tornillería + bujes | M12/M16, arandelas grasas, bujes de nylon/impresos | lote | US$12 |

**Subtotal C ≈ US$110–130**

> Aquí es donde entran las **piezas de bicicleta e hidráulicas**: el pedalier/buje da el giro de 360° con rodamiento sellado y barato; el headset da las juntas; el QR da el bloqueo tipo "tuerca de leva" del Omni; y el resorte de gas cubre el desplazamiento vertical para agacharse/saltar.

---

## D. Calzado deslizante (overshoes)

Se calzan **sobre** las zapatillas. Suela de baja fricción (negra, deslizante) + sección de agarre (verde, para entrar/salir), tal como el Omni One. Chasis impreso en 3D.

| # | Componente | Material / Especificación | Cant. (par) | Costo aprox. |
|---|-----------|---------------------------|-------|-------------|
| D1 | Chasis del overshoe | **Impreso 3D** (PETG, suela ligeramente curva para casar con el cuenco) | 2 | US$6 (filamento) |
| D2 | Almohadilla deslizante | Disco de **PTFE / UHMW** o deslizador de muebles de PTFE Ø50–60 mm | 2–4 | US$8 |
| D3 | Sección de agarre | Parche de goma/EVA de alta tracción, retráctil o en el talón | 2 | US$5 |
| D4 | Correas de sujeción | Velcro ancho + hebillas *o* **correas de calapié de bici (toe straps)** | 2 juegos | US$8 |
| D5 | Plantilla / soporte del sensor | Alojamiento impreso para el tracker IMU en el empeine/talón | 2 | incl. |

**Subtotal D ≈ US$27**

---

## E. Sensores de pies (foot trackers IMU) — 1 por pie

Electrónica estilo **SlimeVR**: ESP32 + IMU 9-DOF por pie, con sensor de presión de talón (FSR) opcional para detectar la pisada. Alimentado por LiPo. Carcasa impresa.

| # | Componente | Material / Especificación | Cant. | Costo aprox. |
|---|-----------|---------------------------|-------|-------------|
| E1 | Microcontrolador | **ESP32** (WROOM) o ESP32-C3 mini (WiFi/BLE + ESP-NOW) | 2 | US$8 |
| E2 | **IMU 9-DOF** | **MPU-9250** o **ICM-20948** (accel+gyro+magnetómetro) — el mag da rumbo absoluto | 2 | US$10 |
| E3 | Sensor de pisada (opcional) | **FSR** (force-sensitive resistor) 0.5" en el talón, para heel-strike/toe-off | 2 | US$6 |
| E4 | Batería | LiPo 3.7 V 500–1000 mAh | 2 | US$8 |
| E5 | Cargador / protección | Módulo **TP4056** con protección | 2 | US$3 |
| E6 | Interruptor + LED estado | Micro-switch + LED RGB (verde=OK, parpadeo=pairing, como el Omni) | 2 | US$3 |
| E7 | Carcasa impresa 3D | PLA/PETG, clip al overshoe | 2 | incl. |
| E8 | Cableado / JST / resistencias | Divisor del FSR (10k), cables, headers | lote | US$4 |

**Subtotal E ≈ US$42**

---

## F. Electrónica hub / puente a la PC

Un ESP32 receptor recibe ambos pies por ESP-NOW, fusiona el vector de locomoción y se presenta a la PC como **mando USB (HID gamepad)** — así funciona con cualquier juego/SteamVR sin driver propietario.

| # | Componente | Material / Especificación | Cant. | Costo aprox. |
|---|-----------|---------------------------|-------|-------------|
| F1 | MCU receptor con USB nativo | **ESP32-S3** (USB HID nativo) o ESP32 + módulo USB | 1 | US$7 |
| F2 | Carcasa + montaje | Impresa 3D, fija al poste | 1 | incl. |
| F3 | Cable USB a PC | USB-C, 3 m + alargador (alejar antena del ruido USB3) | 1 | US$5 |
| F4 | (Opcional) OLED de diagnóstico | SSD1306 0.96" (estado, batería, vector) | 1 | US$4 |

**Subtotal F ≈ US$16**

---

## G. Consumibles

| # | Componente | Especificación | Costo aprox. |
|---|-----------|----------------|-------------|
| G1 | **Lubricante de silicona** en spray | Equivalente al "EASY-WALK" del Omni; reduce fricción del cuenco | US$8 |
| G2 | Filamento 3D | ~1.5 kg PLA/PETG total (juntas, calzado, carcasas, patrones) | US$30 |
| G3 | Poliuretano/sellador + lija | Para acabado liso del cuenco | US$12 |
| G4 | Grasa para rodamientos | Bici/multiuso | US$5 |

**Subtotal G ≈ US$55**

---

## Resumen de costos

| Subsistema | Costo aprox. |
|-----------|-------------|
| A. Cuenco cóncavo | US$90–110 |
| B. Estructura y base | US$90 |
| C. Brazo + hub + arnés | US$110–130 |
| D. Calzado deslizante | US$27 |
| E. Sensores de pies | US$42 |
| F. Electrónica hub | US$16 |
| G. Consumibles | US$55 |
| **TOTAL** | **≈ US$430** (realista US$250–350 rescatando material) |

---

## Piezas impresas en 3D (índice — ver `cad/openomni.scad`)

1. `costilla_patron` — plantilla del perfil parabólico para trazar sobre contrachapado
2. `abrazadera_junta` — abrazaderas de las juntas abisagradas del brazo (×3)
3. `hub_tapa` — tapa/guía del rodamiento del hub rotatorio
4. `overshoe_chasis` — chasis del calzado deslizante (×2, espejado)
5. `sensor_carcasa` — carcasa del tracker IMU (×2)
6. `hub_carcasa` — carcasa de la electrónica receptora
7. `ancla_chaleco` — placa de anclaje brazo↔arnés

## Herramientas necesarias

Sierra de calar (jigsaw), taladro, atornillador, llaves, **impresora 3D** (≥200×200 mm), soldadora (si se usa acero; opcional si todo es madera+pernos), lijadora, pistola de silicona/cola.
