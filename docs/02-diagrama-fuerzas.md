# OpenOmni — Diagrama de Fuerzas y Cálculos Estructurales

Análisis estático (con factores dinámicos) de los subsistemas que soportan carga. Todo pasivo: **la gravedad hace el trabajo de recentrar el pie**; la estructura solo debe (a) dejar deslizar el pie con poca fricción y devolverlo al centro, y (b) sostener al usuario sin volcar.

## 0. Parámetros de diseño

| Símbolo | Valor | Nota |
|---|---|---|
| m_max | 113 kg | usuario máximo (= Omni One) |
| W | **1110 N** | peso usuario = m·g (g=9.81) |
| R | 600 mm | radio útil del cuenco |
| perfil | z = k·r² | parábola |
| θ_borde | 13° | pendiente en el borde |
| k | 1.924×10⁻⁴ /mm | de tan13° = 2·k·R |
| z_borde | 69.3 mm | profundidad del centro respecto al borde |
| Φ (factor dinámico) | 2.5–3.0× | pico de impacto al correr/saltar |
| μ_objetivo | **0.08–0.12** | PTFE/UHMW + lubricante de silicona sobre superficie sellada |

---

## 1. Geometría del cuenco y auto-recentrado (self-centering)

En el radio `r`, la pendiente local es `tanθ(r) = 2·k·r`. El peso del pie apoyado (`W_pie`, hasta = W en apoyo monopodal) se descompone:

```
        superficie
         del cuenco
            \  N (normal) = W·cosθ
             \ ^
              \|
   pie ●───────\────────► F_rest = W·sinθ  (tangencial, hacia el CENTRO)
               |\
               | \
       W (peso)v  \θ
                   \
   ────────────────•──────  hacia el centro del cuenco
```

- **Fuerza de recentrado** (la que devuelve el pie al centro): `F_rest = W_pie · sinθ`
- **Normal:** `N = W_pie · cosθ`
- **Condición para que el pie DESLICE de vuelta solo** (no se quede pegado): `F_rest > μ·N` ⟹ **`tanθ > μ`**

Mapa del cuenco (con W_pie = W = 1110 N, apoyo en un pie):

| r (mm) | θ | z (mm) | F_rest (N) | μ necesario para retornar |
|-------:|----:|------:|-----------:|--------------------------:|
| 0   | 0°    | 0    | 0   | — |
| 100 | 2.2°  | 1.9  | 43  | <0.038 |
| 200 | 4.4°  | 7.7  | 85  | <0.077 |
| 300 | 6.6°  | 17.3 | 127 | <0.115 |
| 400 | 8.8°  | 30.8 | 169 | <0.154 |
| 500 | 10.9° | 48.1 | 210 | <0.192 |
| 600 | 13.0° | 69.3 | 250 | <0.231 |

**Lecturas de diseño:**
- Con **μ ≈ 0.10**, el pie se auto-recentra para `r > 260 mm` (donde tanθ=0.10). Dentro de ese radio hay una pequeña "zona muerta" central donde la fricción retiene el pie — irrelevante: el siguiente paso lo corrige. Es el mismo compromiso del Omni One.
- **No bajar de 13° ni subir mucho:** el borde exige F_rest=250 N por paso. Más pendiente = más fatiga del tibial (la queja clásica); menos = el usuario deriva y choca contra el arnés. **13° es el punto dulce** (coincide con los builds DIY de 13–15°).
- Toda la ingeniería de fricción (PTFE/UHMW + silicona) existe para mantener **μ < 0.12**. Es el requisito #1 del proyecto.

---

## 2. Cuerpo libre del usuario + arnés (fuerza de lean)

Para "caminar en el sitio" el usuario se **inclina** contra el chaleco (péndulo invertido apoyado en los pies y sostenido atrás por el brazo).

```
              cabeza
               ●
              /|            φ = ángulo de inclinación
             / |
   chaleco  /  |  P_h  (horizontal, el brazo lo retiene)
    ═════► ▓   |──►
           /   |
          /    | W_user (peso, vertical)
         /     v
    pie ●──────┴──  cuenco
```

Modelando el cuerpo como péndulo invertido, la fuerza horizontal que el chaleco/brazo debe reaccionar:

`P_h ≈ W_user · tanφ`

| Actividad | φ (lean) | P_h |
|---|---|---|
| Caminar suave | 10° | 196 N |
| Trote | 15° | 297 N |
| Sprint | 25° | 517 N |
| Sprint + pico dinámico (×1.3) | — | **≈ 600–670 N** |

**Carga de diseño del arnés:**
- Horizontal: **P_h = 600 N**
- Vertical (el usuario "cuelga" parte del peso / el gas strut la sostiene): **P_v = 350 N** (≈0.3·W)

---

## 3. Cuerpo libre del brazo articulado

Geometría (origen en el poste trasero, a ras de piso):
- Collar rotatorio del brazo en el poste, a **h_c = 350 mm**.
- Chaleco a **h_v = 1050 mm** de alto y **d_v = 550 mm** por delante del poste.
- Brazo carga P_h (horizontal) y P_v (vertical) en el chaleco.

```
           chaleco (P_h→, P_v↓)
                ●·····························►  P_h = 600 N
               /:                          
              / : Δy = h_v−h_c = 700 mm    
   eslabón   /  :                          
   superior /   :                          
           /    :                          
   junta  ◉ ....:                          
         /      d_v = 550 mm               
        / eslabón inferior                 
collar ◎══════════ poste ═══════ (rodamiento de giro 360°)
       ║ h_c=350                           
   ════╩════ placa base ═══ piso           
```

**Momento flector en el collar** (peor caso, sumando conservador):
- por P_h:  M₁ = P_h · Δy = 600 N × 0.70 m = **420 N·m**
- por P_v:  M₂ = P_v · d_v = 350 N × 0.55 m = **193 N·m**
- **M_collar ≈ 610 N·m**

Este momento lo reaccionan el rodamiento del hub (§4) y el poste (§5).

**Verificación del tubo del brazo** (acero 30×30×2 mm SHS):
- Z ≈ 2.06×10³ mm³ ; σ = M₁/Z (en el tramo más cargado) — el eslabón inferior ve el momento completo cerca del collar.
- Con M=610 N·m: σ = 610000/2060 = **296 MPa** → ¡supera el límite de acero dulce (250 MPa)!
- **Corrección:** usar tubo **40×40×3 mm** (Z ≈ 4.6×10³ mm³) → σ = 133 MPa, **SF ≈ 1.9**. ✔️ *(Actualiza B/C: el eslabón inferior y el collar en 40×40×3, no 30×30×2.)*

---

## 4. Rodamiento del hub rotatorio (giro 360°)

El momento M_collar debe transformarse en un **par de fuerzas** entre dos rodamientos separados una distancia `s` en el eje del poste:

`F_bearing = M_collar / s`

| Separación s | F por rodamiento | Componente sugerido |
|---|---|---|
| 250 mm | 2440 N | marginal para 6008 (C≈16 kN estático, pero fatiga) |
| **400 mm** | **1525 N** | **6008 / buje de bici / cazoleta pedalier** ✔️ |
| turntable | — | rodamiento lazy-susan con **rating de momento** directo ✔️ |

**Recomendación:** separar los rodamientos ≥400 mm en el poste **o** usar un rodamiento de **rótula/trailer (cónico ahusado)** rescatado —baratos y con alta capacidad de momento—. Un **pedalier de bici** sellado va perfecto para el rodamiento inferior de empuje; un **buje de rueda** para el superior. Engrasar y sellar contra polvo.

---

## 5. Poste/mástil y su base

El poste (tubo **50×50×3 mm**, §B2) es corto (0.35 m) pero transmite el momento a la placa base:

- Momento en la base ≈ P_h · h_v = 600 × 1.05 = **630 N·m**
- SHS 50×50×3: Z = 8.34×10³ mm³ → σ = 630000/8340 = **75.5 MPa**, **SF ≈ 3.3** ✔️
- **Punto crítico = la unión poste↔placa base.** Soldar con cartelas (gussets) en las 4 caras, o si es atornillado, placa de 6 mm con 4× M10 y triángulos de refuerzo. No confiar en una sola soldadura de filete.

---

## 6. Estabilidad al vuelco (¡el punto más crítico!)

El usuario se inclina hacia adelante; el brazo lo retiene y **jala el poste hacia adelante**, tendiendo a **volcar la máquina hacia el frente** (rotación sobre el borde delantero de la huella).

```
   P_h=600N →  ● chaleco (h=1.05m)
              /|
             / |          Momento de vuelco:
            /  |          M_vuelco = P_h · h_v = 630 N·m
    poste  ◎   |
   ═════════╤══╪═══════════════════════╗
   borde    │  CG_máquina    CG_usuario ║ borde
   trasero  │  (500N)        (1110N)    ║ DELANTERO ← pivote de vuelco
            0  0.5m          0.6m      1.2m
```

Momentos respecto al **borde delantero** (x = 1.2 m):
- **Vuelco:** M_v = 600 N × 1.05 m = **630 N·m**
- **Resistente (máquina):** 500 N × (1.2−0.5) = 350 N·m
- **Resistente (usuario centrado):** 1110 N × (1.2−0.6) = 666 N·m
- Total resistente = 1016 N·m → **SF = 1.6** *si el usuario está centrado.*

⚠️ **Problema:** durante un **salto** el peso del usuario desaparece un instante → SF cae a **350/630 = 0.56 → ¡VUELCA!**

**Solución (obligatoria):** no depender del peso del usuario. Igual que el Omni One pesa 70 kg **a propósito**, hay que **lastrar la base**:

- Añadir **≈25–30 kg de lastre** (bloques de concreto, arena en cajones del marco, o pavers) en la mitad trasera → M_máquina sube a ~900–1000 N·m sin el usuario → **SF ≥ 2.0** aun en salto. ✔️
- **o** anclar la placa base al piso (si es instalación fija).
- **o** ampliar la huella con **outriggers/patas delanteras** a 1.4–1.5 m.

> El lastre es casi gratis (arena/concreto) y es la forma correcta de resolverlo. **Diséñalo pesado.**

---

## 7. Resorte de gas (compliance vertical, agacharse/saltar)

El gas strut sostiene la fracción vertical `P_v ≈ 350 N` y devuelve suave al usuario tras agacharse.

- Fuerza de extensión del strut ≈ P_v ajustada por la relación de palanca de su montaje en el brazo. Montado casi vertical en el eslabón: **F_strut ≈ 300–400 N**.
- **Componente:** cilindro de **silla de oficina** (regulable, ~US$10) o amortiguador de portón de auto de **250–400 N**. Carrera ≥120 mm para permitir un squat parcial.
- El giro 360° del hub + la junta abisagrada horizontal permiten girarse; el gas strut da el eje vertical.

### 7.1 Física del brazo hidráulico (¿cómo sostiene al usuario al "dejarse caer"?)

El brazo va **como una mochila**: placa en la espalda → 2 eslabones → hub que **gira 360°** sobre un rodamiento de bici en el poste trasero. Es un **mecanismo pasivo** (juntas de revolución + muelle de gas). Al dejarte caer hacia atrás, el brazo baja y el **resorte de gas** te frena y sostiene.

**Muelle neumático (gas spring):** un pistón encierra N₂ a presión `P₀`. Al comprimir el vástago una distancia `x`, el volumen baja y la presión sube según un proceso casi adiabático:

```
P · Vᵞ = const     (γ ≈ 1.4 para N₂)
```

La fuerza de soporte es la presión por el área efectiva del vástago:

```
F(x) = P(x) · A_ef ,   con  P(x) = P₀ · ( V₀ / (V₀ − A_ef·x) )ᵞ
```

- **Muelle progresivo:** como `P` crece al comprimir, `F` aumenta con la caída → cuanto más te dejas caer, más te empuja (auto-limita el descenso). Ideal para un "catch" suave.
- **Amortiguación viscosa:** el sellado con aceite añade `F_d = c·v` (proporcional a la velocidad del vástago) → elimina el rebote elástico. Por eso un gas strut "cae lento y sube lento".
- **Dimensionado:** para sostener `P_v ≈ 0.32·W` en un usuario de 113 kg → `F ≈ 350 N` de extensión nominal. Un cilindro de silla de oficina (100 kg de rating) o un amortiguador de portón de 300–400 N cumplen. La palanca real depende de dónde lo montes en el eslabón (ver el modelo 3D / webapp).

### 7.2 Cinemática: ¿hace falta cinemática inversa (IK)?

**En el aparato real: NO.** El brazo no tiene motores ni control; es **compliante** y sigue tu espalda por pura mecánica (como un brazo de flexo/lámpara). Los grados de libertad:
1. **Rotación del hub (yaw, 360°)** → te giras y el brazo te sigue alrededor de la plataforma.
2. **Junta abisagrada vertical (pitch)** → subes/bajas, te agachas/saltas; aquí actúa el gas strut.
3. (Opcional) una **rótula** en la placa de la espalda → inclinación lateral del torso.

Con esos 3 GDL pasivos, el extremo alcanza tu espalda en cualquier pose sin cálculo alguno.

**En la simulación (webapp): SÍ uso IK de 2 eslabones** — sólo para *dibujar* el brazo persiguiendo el punto de la mochila cuando cambias **altura/peso/giro/inclinación**. Ley de cosenos para el ángulo del codo:

```
D = |espalda − hub|            (alcance requerido)
cos(codo) = (D² − L₁² − L₂²) / (2·L₁·L₂)
hombro    = atan2(Δy, Δh) + acos( (D² + L₁² − L₂²) / (2·L₁·D) )
```

Así el gemelo digital muestra cómo el brazo **se ajusta solo** a personas de distinta talla (prueba los sliders de peso 40–120 kg y altura 1.50–2.00 m). En hardware, ese ajuste lo hace la física; en pantalla, la IK.

---

## 8. Esfuerzos de contacto (verificación de materiales)

**Almohadilla del calzado (PTFE/UHMW):**
- Fuerza normal pico por pie = Φ·W = 2.5 × 1110 = **2775 N**
- Pad Ø55 mm → A = 2376 mm² → presión = **1.17 MPa**
- PTFE resistencia a compresión ~10–20 MPa → **OK**, pero el PTFE **fluye (creep)** bajo carga sostenida → usar **UHMW o PTFE con carga de vidrio/bronce** para durabilidad. ✔️

**Piel del cuenco entre costillas:**
- A 14 costillas, separación en el borde = 2π·600/14 = **269 mm**.
- Piel de 3–4 mm bajo parche de ~1 MPa flecta demasiado en 269 mm.
- **Corrección:** doble piel (luan 3 mm + hardboard 3 mm) **o** 16 costillas (separación ≤235 mm) **o** superficie superior rígida de HDPE 2 mm que reparte la carga. ✔️

---

## 9. Resumen: cargas de diseño → especificación de componentes

| Elemento | Carga de diseño | Especificación resultante |
|---|---|---|
| Superficie del cuenco | μ < 0.12 | PTFE/UHMW/hardboard sellado + silicona |
| Fuerza de recentrado | 250 N máx (borde) | pendiente 13° |
| Chaleco/arnés | 600 N horiz + 350 N vert | arnés acolchado, anclaje impreso reforzado |
| Eslabón inferior del brazo | M = 610 N·m | **tubo acero 40×40×3 mm** (SF 1.9) |
| Rodamiento del hub | 1525 N/rod. (s=400) | pedalier+buje de bici, o cónico de trailer, o lazy-susan |
| Poste/mástil | M = 630 N·m | **SHS 50×50×3** + cartelas (SF 3.3) |
| Estabilidad al vuelco | 630 N·m vuelco | **lastre ≥25–30 kg** o anclaje (SF ≥2.0) |
| Gas strut | 300–400 N | cilindro silla oficina / amortiguador portón |
| Pad del calzado | 2775 N (1.17 MPa) | UHMW / PTFE cargado, Ø≥55 mm |
| Costillas del cuenco | parche ~1 MPa | ≥16 costillas o doble piel |

> **Cambios que este análisis fuerza en la BOM:** (1) el eslabón inferior del brazo sube a **40×40×3 mm** (no 30×30); (2) añadir **lastre de 25–30 kg** a la base; (3) **16 costillas** o doble piel en el cuenco. Ya reflejar esto en `01-lista-componentes.md` en la próxima revisión.
