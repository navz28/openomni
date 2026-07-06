# OpenOmni 🏃‍♂️🕹️

**Treadmill omnidireccional pasiva, DIY e imprimible en 3D — clon funcional del Virtuix Omni One** con madera, tubo de PVC/fierro, piezas de bicicleta, un resorte de gas hidroneumático y electrónica estilo SlimeVR.

> Objetivo: la misma experiencia (caminar/correr 360° dentro de VR sin marearse) por **~US$250–430** en vez de **US$2,600–3,500**.

## Principio de diseño
Igual que el Omni One, **no hay motores**: un **cuenco cóncavo parabólico** de baja fricción + **calzado deslizante** hacen que la gravedad recentre el pie tras cada paso. Un **brazo articulado posterior** que gira 360° sobre un rodamiento (de bici) sostiene al usuario por un **chaleco**, con un **resorte de gas** para agacharse/saltar. Sensores **IMU** en los pies traducen las zancadas a locomoción, presentándose a la PC como un **mando USB** (sin drivers propietarios).

## Contenido del repo
```
treadmill/
├── README.md                 <- esto
├── index.html                <- SIMULACIÓN INTERACTIVA 3D (Three.js) para GitHub Pages
├── geminideepresearch.txt    <- investigación de partida sobre el Omni One
├── docs/
│   ├── 01-lista-componentes.md   <- BOM por subsistema + costos  (ENTREGABLE 1)
│   ├── 02-diagrama-fuerzas.md     <- física + hidráulica + IK     (ENTREGABLE 2)
│   └── 03-referencia-woodt.md     <- armado en madera (octágono, video/WoODT)
├── cad/
│   ├── openomni.scad             <- modelo 3D paramétrico         (ENTREGABLE 3)
│   ├── README.md                 <- cómo renderizar/exportar STL
│   ├── assembly.png / side.png   <- renders del conjunto
│   └── *.stl                     <- piezas imprimibles exportadas
└── firmware/                     <- código + drivers de sensores  (ENTREGABLE 4)
    ├── README.md                 <- cableado, librerías, flasheo
    ├── openomni_protocol.h       <- trama pie→hub (0x55 + seq + CRC16)
    ├── foot_tracker/             <- ESP32-C3 + IMU + FSR (×2)
    ├── hub/                      <- ESP32-S3 → mando USB
    └── pc_bridge.py              <- driver PC alterno (modo serie)
```

## Subsistemas (resumen)
| # | Subsistema | Material clave | Ref. |
|---|---|---|---|
| A | Cuenco cóncavo 13° Ø1.2 m (**octágono de 8 módulos**, estilo WoODT) | contrachapado + piel laminada + HDPE/hardboard + silicona | docs/01 §A |
| B | Estructura + base | fierro 40–50 mm / madera + **lastre 25–30 kg** | docs/01 §B |
| C | Brazo articulado + hub 360° + arnés | tubo acero + **rodamiento/pedalier de bici** + **gas strut** | docs/01 §C |
| D | Calzado deslizante | impreso 3D + **PTFE/UHMW** | docs/01 §D |
| E | Trackers de pie | ESP32-C3 + MPU-9250 + FSR + LiPo | firmware/ |
| F | Hub / puente PC | ESP32-S3 (mando USB) | firmware/ |

## Simulación interactiva (webapp)
`index.html` es un **gemelo digital** en Three.js (autocontenido, para **GitHub Pages**):
- **Humanoide paramétrico** (peso 40–120 kg, altura 1.50–2.00 m) que **camina** en el cuenco.
- **Brazo hidráulico tipo mochila** con **hub que gira 360°** e **IK de 2 eslabones** que se adapta a la talla; botón **«Dejarse caer»** que comprime el gas strut.
- **Flechas de fuerza** en vivo (peso, normal, recentrado, arnés, strut) con lecturas numéricas.
- **Cuenco octagonal** de 8 módulos; **piezas impresas 3D coloreadas** (naranja) e **hidráulica** (turquesa) con leyenda.
- **Ensamblaje animado** (botones Ensamblar/Explotar) y **descargas STL**.

Preview local (tienes node): `npx serve .` y abre `http://localhost:3000` (o abre `index.html` en tu Chromium). Despliegue en Pages: ver abajo.

## Números de diseño (del análisis de fuerzas)
- Usuario máx **113 kg** (W=1110 N); pendiente del cuenco **13°** → recentrado ≤250 N/paso.
- Fricción objetivo **μ < 0.12** (PTFE/UHMW + silicona) = requisito #1.
- Chaleco: **600 N** horiz + 350 N vert. Brazo inferior **tubo 40×40×3** (SF 1.9). Poste **50×50×3** (SF 3.3).
- **Vuelco: hay que lastrar ≥25–30 kg** o vuelca en los saltos (por eso el Omni pesa 70 kg a propósito).

## Orden de construcción sugerido
1. **Cuenco** (A): corta las 16 costillas con la plantilla `cad → rib_template.stl`, ensámblalas radiales, forra, alisa y sella. Prueba la fricción con el calzado antes de seguir.
2. **Base + poste + lastre** (B).
3. **Hub + brazo + arnés** (C): monta el rodamiento de bici, los eslabones y el gas strut; ajusta para tu altura.
4. **Calzado** (D): imprime, pega los PTFE.
5. **Electrónica** (E/F): flashea los 2 pies + el hub, calibra el "adelante", mapea el stick en SteamVR.

## Estado
- [x] Investigación consolidada (+ referencia de armado en madera WoODT)
- [x] Lista de componentes (BOM)
- [x] Diagrama de fuerzas y cálculos (+ física de la hidráulica + IK)
- [x] Modelo 3D en OpenSCAD (renders + STL validados)
- [x] Firmware trackers + hub + puente PC (protocolo validado)
- [x] Webapp interactiva (humanoide, fuerzas, ensamblaje, hidráulica)
- [ ] **Siguiente:** construir el prototipo del cuenco y medir la fricción real (μ) del par superficie/PTFE.

## Desplegar en GitHub Pages
El repo ya está listo (git inicializado y commiteado). Para publicarlo:
```bash
# 1) re-autenticar gh (el token del keyring caducó)
gh auth login
# 2) crear el repo y subir  (público para que Pages funcione en cuenta free)
gh repo create openomni --public --source=. --remote=origin --push
# 3) activar Pages sirviendo desde la raíz de main
gh api -X POST repos/:owner/openomni/pages -f source[branch]=main -f source[path]=/ 2>/dev/null || \
  echo "Actívalo a mano: Settings → Pages → Branch: main / (root)"
```
La app quedará en `https://<usuario>.github.io/openomni/`. Los STL (`cad/*.stl`) se sirven junto a la web para las descargas.

## Fuentes de la investigación
- Virtuix Omni One (specs, patentes, SDK): `geminideepresearch.txt`
- Builds DIY de referencia (ángulo de cuenco 13–15°, deslizadores): [Hackaday](https://hackaday.com/2014/02/18/low-budget-omnidirectional-treadmill/), [Instructables TolDish](https://www.instructables.com/TolDish-a-DIY-Omnidirectional-Treadmill/)
- Tracking de pies open-source: [SlimeVR-Tracker-ESP](https://github.com/SlimeVR/SlimeVR-Tracker-ESP)
