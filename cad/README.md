# OpenOmni — Modelo 3D (OpenSCAD)

Modelo **paramétrico** de toda la treadmill en `openomni.scad`. Cambiando las variables de la cabecera (radio `R`, ángulo del borde `edge_angle`, nº de costillas `n_ribs`, etc.) se re-genera todo, incluidas las plantillas de corte.

## Requisitos
OpenSCAD 2021.01+ (ya instalado: `/usr/bin/openscad`).

## Ver el conjunto en la GUI
```bash
openscad cad/openomni.scad
```

## Seleccionar qué pieza mostrar/exportar
La variable `part` elige el objeto. Valores: `assembly`, `bowl`, `rib_template`, `overshoe`, `sensor_case`, `arm_hub`.

## Exportar STL de las piezas imprimibles
```bash
cd cad
openscad -o overshoe.stl    -D 'part="overshoe"'     openomni.scad   # calzado deslizante (x2, uno espejado)
openscad -o sensor_case.stl -D 'part="sensor_case"'  openomni.scad   # carcasa tracker IMU (x2)
openscad -o arm_hub.stl     -D 'part="arm_hub"'       openomni.scad   # abrazadera/hub del brazo
openscad -o rib_template.stl -D 'part="rib_template"' openomni.scad   # plantilla de UNA costilla
```
> `rib_template` es una lámina de 4 mm: imprímela, pégala sobre el contrachapado y usa el perfil para cortar las 16 costillas con sierra de calar. Las marcas grabadas cada 100 mm son las líneas de radio.

## Renderizar imágenes
```bash
DISPLAY=:0 openscad -o assembly.png --imgsize=1100,850 \
  --camera=0,0,0,62,0,32,0 --viewall --autocenter \
  --colorscheme=Tomorrow -D 'part="assembly"' openomni.scad
```
Ya generadas: `assembly.png` (isométrica) y `side.png` (lateral).

## Imprimir el calzado espejado
El pie derecho es el modelo tal cual; para el izquierdo, espeja en el laminador (o añade `mirror([0,1,0])` antes de `overshoe()`).

## Parámetros clave (cabecera del .scad)
| Variable | Valor | Significado |
|---|---|---|
| `R` | 600 | radio útil del cuenco (mm) |
| `edge_angle` | 13 | pendiente en el borde (°) — **no subir**, ver análisis de fuerzas |
| `n_ribs` | 16 | costillas radiales |
| `k` | derivado | coef. de la parábola `z=k·r²` |

## Piezas del modelo
- **Cuenco** (`bowl` + costillas): dish parabólico + 16 costillas radiales.
- **Estructura**: aro base, largueros, poste trasero 50×50, lastre.
- **Brazo articulado**: hub rotatorio, 2 eslabones, bisagra, gas strut, placa de chaleco.
- **Calzado** (`overshoe`): suela con rocker, 3 almohadillas PTFE Ø55, ranuras de correa, pod del sensor.
- **Carcasa sensor** (`sensor_case`): caja 52×40×26 con postes para ESP32 y ranura USB-C/LED.
- **Hub imprimible** (`arm_hub`): abraza el tubo del eslabón y aloja el rodamiento de bici (Ø42).

## Nota
Es un modelo de **diseño/fabricación y visualización**, no un gemelo CAD con tolerancias de máquina. Las piezas de madera/acero se cortan con las plantillas y las dimensiones de la BOM; las piezas imprimibles (calzado, carcasas, hub, abrazaderas) salen directas a STL.
