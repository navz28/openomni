// ============================================================
//  OpenOmni  -  Treadmill omnidireccional pasiva DIY
//  Modelo parametrico inspirado en el Virtuix Omni One
//  Unidades: milimetros
//  OpenSCAD 2021.01+
// ============================================================
//  Que renderizar:
//   "assembly"     -> conjunto completo (vista)
//   "bowl"         -> cuenco solido (referencia de construccion)
//   "rib_template" -> plantilla de UNA costilla para trazar/cortar
//   "overshoe"     -> calzado deslizante (imprimible)
//   "sensor_case"  -> carcasa del tracker IMU (imprimible)
//   "arm_hub"      -> abrazadera/hub del brazo (imprimible)
part = "assembly";

// ---------- Parametros globales del cuenco ----------
R          = 600;   // radio util del cuenco (mm)
edge_angle = 13;    // pendiente en el borde (grados)
k          = tan(edge_angle) / (2 * R);   // z = k * r^2
rim_w      = 55;    // ancho del aro de borde
base_h     = 40;    // espesor de la base bajo el centro
n_ribs     = 16;    // costillas radiales (ver analisis de fuerzas)
skin_t     = 6;     // piel (luan 3 + hardboard 3)

function zbowl(r) = k * r * r;               // altura de la parabola
zR = zbowl(R);                               // profundidad del borde (~69 mm)

$fn = 96;

// ============================================================
//  CUENCO
// ============================================================
module bowl_solid() {
    steps = 48;
    top = [ for (i=[0:steps]) let(r = R*i/steps) [r, zbowl(r)] ];
    profile = concat(
        top,
        [ [R+rim_w, zR+18],            // labio exterior del aro
          [R+rim_w, -base_h],          // baja al fondo de la base
          [0,       -base_h] ]         // vuelve al centro
    );
    color("burlywood")
        rotate_extrude($fn=140) polygon(profile);
}

// Perfil 2D de UNA costilla (seccion radial): arriba parabola, abajo plano
module rib_profile() {
    steps = 40;
    top = [ for (i=[0:steps]) let(r = R*i/steps) [r, zbowl(r)] ];
    polygon( concat(top, [ [R, -base_h], [0, -base_h] ]) );
}

// Costillas de madera dispuestas radialmente (vista de construccion)
module ribs() {
    rib_t = 15; // espesor del contrachapado
    color("peru")
    for (a = [0 : 360/n_ribs : 359.9])
        rotate([0,0,a])
            translate([0,-rib_t/2,0])
                rotate([90,0,0])              // parar la costilla vertical
                    rotate([0,-90,0])
                        linear_extrude(rib_t)
                            rib_profile();
}

// Plantilla imprimible/trazable de una costilla, con ranuras de ensamble
module rib_template() {
    slot_w = 15; slot_d = base_h*0.6;
    difference() {
        linear_extrude(4) rib_profile();
        // ranuras cada 150 mm para media-madera con anillos concentricos
        for (r = [150 : 150 : R-60])
            translate([r, -base_h/2, -1])
                cube([slot_w, slot_d, 6], center=true);
    }
    // marcas de radio grabadas
    for (r = [100:100:R])
        translate([r, zbowl(r)+3, 4])
            color("black") cube([1, 6, 1], center=true);
}

// ============================================================
//  ESTRUCTURA / BASE
// ============================================================
module square_ring(rad, sec=40) {
    rotate_extrude($fn=120)
        translate([rad,0,0]) square([sec,sec], center=true);
}

module base_frame() {
    color("dimgray") {
        // aro estructural bajo el borde del cuenco
        translate([0,0,-base_h]) square_ring(R+rim_w-20, 40);
        // largueros cruzados
        for (a=[0,90])
            rotate([0,0,a])
                translate([0,0,-base_h])
                    cube([2*(R+rim_w), 40, 40], center=true);
    }
}

// Poste trasero (mastil) que sostiene el hub rotatorio
module rear_post() {
    post = 50; H = 350;
    color("gray")
    translate([R+rim_w-10, 0, -base_h])
        cube([post, post, H+base_h]);
}

// Lastre anti-vuelco (cajones de arena/concreto en la mitad trasera)
module ballast() {
    color("saddlebrown", 0.6)
    translate([R*0.55, -R*0.5, -base_h+5])
        cube([R*0.5, R, 30]);
}

// ============================================================
//  HUB ROTATORIO + BRAZO ARTICULADO
// ============================================================
// Abrazadera/hub imprimible que abraza dos tubos (rodamiento de bici dentro)
module arm_hub() {
    od = 70; id = 42; h = 60; // id = OD del rodamiento/pedalier
    difference() {
        union() {
            cylinder(d=od, h=h);
            translate([-od/2,0,0]) cube([od, od*0.9, h]); // brazo de union
        }
        translate([0,0,-1]) cylinder(d=id, h=h+2);       // alojamiento rodamiento
        // agujero para el tubo del eslabon (40x40)
        translate([od*0.2, od*0.45, h/2]) rotate([90,0,0])
            cube([42,42,od], center=true);
        // tornillos de fijacion
        for (z=[15,45]) translate([0,od*0.6,z]) rotate([90,0,0]) cylinder(d=6,h=30,center=true);
    }
}

// Brazo articulado completo (vista de conjunto)
module arm_assembly() {
    hub_top = 350;
    // hub sobre el poste
    color("orange")
        translate([R+rim_w+15, 0, hub_top-base_h]) rotate([0,0,0]) cylinder(d=70,h=70);
    // eslabon inferior (40x40x3) subiendo y hacia adelante
    color("silver")
        translate([R+rim_w+15, -20, hub_top])
            rotate([0,-35,0]) cube([40,40,650]);
    // junta abisagrada
    color("red")
        translate([R+rim_w-370, 0, hub_top+520]) rotate([90,0,0]) cylinder(d=45,h=50,center=true);
    // eslabon superior hacia el chaleco
    color("silver")
        translate([R+rim_w-380, -20, hub_top+520])
            rotate([0,-70,0]) cube([40,40,520]);
    // placa del chaleco
    vest_plate();
    // gas strut (resorte de gas) esquematico
    color("black")
        translate([R+rim_w-100, 0, hub_top+120])
            rotate([0,-52,0]) cylinder(d=20,h=430);
}

module vest_plate() {
    color("navy")
    translate([50, 0, 1050])
        rotate([0,15,0])
            difference() {
                cube([30, 360, 260], center=true);
                cube([40, 260, 160], center=true); // hueco ergonomico
            }
}

// ============================================================
//  CALZADO DESLIZANTE (imprimible, PETG)
// ============================================================
module overshoe() {
    L=300; W=120; wall=4; base=6;
    difference() {
        union() {
            // suela con ligero rocker
            hull() {
                translate([0,0,0])      cube([L,W,base], center=true);
                translate([0,0,3])      cube([L*0.7,W*0.8,base], center=true);
            }
            // paredes laterales bajas para envolver la zapatilla
            difference() {
                translate([0,0,25]) cube([L,W,50], center=true);
                translate([0,0,32]) cube([L-2*wall,W-2*wall,60], center=true);
                translate([0,0,55]) cube([L-2*wall*2,W+10,40], center=true); // abre arriba
            }
        }
        // ranuras para correas
        for (x=[-L*0.28, L*0.28])
            translate([x,0,20]) cube([14,W+10,8], center=true);
    }
    // almohadillas deslizantes PTFE/UHMW (3 puntos)
    color("black")
    for (p = [[-L*0.32,0],[L*0.28,-W*0.22],[L*0.28,W*0.22]])
        translate([p[0],p[1],-base/2-3]) cylinder(d=55,h=6,$fn=48);
    // pod del sensor en el talon
    color("dimgray")
        translate([-L*0.42,0,15]) cube([40,50,30], center=true);
}

// ============================================================
//  CARCASA DEL SENSOR IMU (imprimible)
// ============================================================
module sensor_case() {
    W=40; L=52; H=26; wall=2.2;
    difference() {
        cube([L,W,H], center=true);
        translate([0,0,wall]) cube([L-2*wall, W-2*wall, H], center=true);
        // ranura USB-C / carga
        translate([L/2, 0, -2]) cube([6,12,8], center=true);
        // LED de estado
        translate([-L/2, 0, 5]) rotate([0,90,0]) cylinder(d=4,h=6,center=true,$fn=24);
    }
    // postes para ESP32
    for (x=[-14,14],y=[-12,12])
        translate([x,y,-H/2+wall]) cylinder(d=5,h=8,$fn=20);
}

// ============================================================
//  CONJUNTO
// ============================================================
module assembly() {
    bowl_solid();
    ribs();
    base_frame();
    rear_post();
    ballast();
    arm_assembly();
    // usuario esquematico (referencia de escala 1.75 m)
    color("lightblue",0.22)
        translate([-40,0,zbowl(0)]) {
            cylinder(d=220,h=820);                 // torso
            translate([0,0,820]) cylinder(d=150,h=150); // cuello
            translate([0,0,1010]) sphere(d=170);   // cabeza
            for (s=[-70,70]) translate([s,0,-40]) cylinder(d=90,h=40); // piernas
        }
    // calzado colocado en el cuenco
    translate([-120,-140, zbowl(150)+8]) scale(0.9) overshoe();
    translate([-120, 140, zbowl(150)+8]) scale(0.9) overshoe();
}

// ---------- selector de render ----------
if (part == "assembly")          assembly();
else if (part == "bowl")         { bowl_solid(); ribs(); }
else if (part == "rib_template") rib_template();
else if (part == "overshoe")     overshoe();
else if (part == "sensor_case")  sensor_case();
else if (part == "arm_hub")      arm_hub();
