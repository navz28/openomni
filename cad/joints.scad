// ============================================================
//  OpenOmni - Juntas impresas en 3D (realistas)
//  Clamps partidos, junta de codo (horquilla + pin de acero),
//  placa de mochila y clamp del hub. Unidades: mm.
//
//  Filosofia: el PLASTICO solo posiciona/abraza; la carga la
//  toma el ACERO (pernos pasantes / pin de la bisagra).
//
//  part: "elbow" | "clamp" | "vest" | "hub" | "all"
// ============================================================
part = "elbow";

// ---------- parametros globales ----------
tol   = 0.40;   // holgura de socket para FDM (deslizante y luego se aprieta)
wall  = 6;      // pared portante minima
$fn   = 72;

M5 = 5.2; M6 = 6.4; M8 = 8.4; M10 = 10.4;   // agujeros pasantes (broca + holgura)
NUT5 = 9.4; NUT6 = 11.5; NUT8 = 14.5;        // entrecaras de tuerca (pocket hex)

module bolt_hole(d, l)   { cylinder(d=d, h=l, center=true); }
module nut_pocket(af, h) { cylinder(d=af/cos(30), h=h, $fn=6); }
module heatset_boss(){ // inserto roscado M5 (Ø4.6 x 8)
    difference(){ cylinder(d=8, h=9); translate([0,0,2]) cylinder(d=4.6, h=8); }
}
// bloque de esquinas redondeadas (agradable de imprimir)
module rbox(x,y,z,r=4){ hull() for(a=[-1,1],b=[-1,1])
    translate([a*(x/2-r), b*(y/2-r), 0]) cylinder(r=r, h=z); }

// ============================================================
//  1) CLAMP PARTIDO para tubo cuadrado (el caballo de batalla)
//     socket con tolerancia + ranura + 2 pernos + tuercas + perno pasante
// ============================================================
module split_clamp_sq(tube=40, len=44, boltM=M5, nutAF=NUT5, thru=true, thruM=M8){
    o = tube + 2*wall;
    difference(){
        rbox(o, o, len, 5);
        // socket del tubo (tolerancia FDM)
        translate([0,0,-1]) linear_extrude(len+2) square(tube+tol, center=true);
        // ranura del split (permite apretar)
        translate([-o, -0.8, -1]) cube([o, 1.6, len+2]);
        // 2 pernos de apriete que cruzan la ranura
        for(z=[len*0.27, len*0.73]) translate([0,0,z]) rotate([0,90,0]){
            bolt_hole(boltM, o+2);
            translate([0,0, o/2-3]) nut_pocket(nutAF, 6);       // tuerca embebida (lado +X)
        }
        // perno de ACERO pasante que atraviesa el tubo (toma el cortante)
        if(thru) translate([0,0,len/2]) rotate([90,0,0]){
            bolt_hole(thruM, o+2);
            translate([0,0, o/2-3]) nut_pocket(NUT8, 6);
        }
    }
}

// ============================================================
//  2) CODO ARTICULADO: horquilla (fork) + hoja (blade) + PIN de acero
//     el pin M10 en doble cortante toma el momento; el plastico abraza
// ============================================================
pin   = M10;
earR  = 12;      // radio de la oreja alrededor del pin
earT  = 9;       // espesor de cada oreja
bladeGap = earT + 2*0.5;  // hueco de la horquilla para la hoja

module ear(bore){ difference(){
    hull(){ cylinder(r=earR, h=earT); translate([0,-earR-4,0]) cube([2*earR,1,earT]); }
    translate([0,0,-1]) cylinder(d=bore, h=earT+2);
}}

// pieza superior: clamp del tubo + HORQUILLA (2 orejas)
module elbow_fork(){
    color("darkorange"){
        translate([0,0,0]) rotate([90,0,0]) split_clamp_sq(40, 44, thru=true);
        // brazo que baja a las orejas
        translate([-10,-52,-(bladeGap/2+earT)]) cube([20,52,bladeGap+2*earT]);
        for(s=[-1,1]) translate([0,-52,s*(bladeGap/2+earT/2)])
            rotate([0,90,0]) translate([0,0,-earT/2]) ear(pin);
    }
}
// pieza inferior: clamp del tubo + HOJA (1 oreja centrada)
module elbow_blade(){
    color("orange"){
        translate([0,0,0]) rotate([90,0,0]) split_clamp_sq(40, 44, thru=true);
        translate([-8,-52,-earT/2]) cube([16,52,earT]);
        translate([0,-52,0]) rotate([0,90,0]) translate([0,0,-earT/2]) ear(pin+0.6); // buje/holgura
    }
}
// pin de acero + arandelas (referencia)
module elbow_pin(){ color("silver"){
    rotate([0,90,0]) cylinder(d=10, h=bladeGap+2*earT+6, center=true);
}}
module elbow(){
    elbow_blade();
    translate([0,0,0]) elbow_fork();
    translate([0,-52,0]) elbow_pin();
}

// ============================================================
//  3) PLACA DE LA MOCHILA (chaleco): baja carga, se puede imprimir
//     placa curva + ranuras de correa + rotula para el brazo
// ============================================================
module vest_plate(){
    w=240; h=300; t=8;
    color("orange") difference(){
        // placa ligeramente curva (se adapta a la espalda)
        intersection(){
            translate([0,0,-t]) rbox(w,h,t,20);
            translate([0,0,-260]) cylinder(r=280, h=300);   // curvatura suave
        }
        // ranuras para correas (4)
        for(y=[-h/2+40, h/2-40]) for(x=[-w/2+30, w/2-30])
            translate([x,y,-t-1]) rbox(14, 40, t+2, 6);
        // 4 agujeros para el anclaje de la rotula del brazo (centro)
        for(a=[0,90,180,270]) rotate([0,0,a]) translate([28,0,-t-1]) bolt_hole(M6, t+2);
    }
    // boss central donde va la rotula/junta del brazo
    color("darkorange") translate([0,0,-t]) difference(){
        cylinder(d=54, h=22); translate([0,0,4]) cylinder(d=26, h=20); // alojamiento rotula
        for(a=[0,90,180,270]) rotate([0,0,a]) translate([28,0,-1]) bolt_hole(M6,26);
    }
}

// ============================================================
//  4) CLAMP DEL HUB: abraza el tubo radial y aloja el bearing central
// ============================================================
module hub_clamp(){
    brgOD=68;   // OD del rodamiento (ej. 6013 / rueda remolque) -> ajustar
    color("orange") difference(){
        union(){
            cylinder(d=brgOD+2*wall, h=26);
            translate([0,-(brgOD/2+wall)+6,13]) rotate([90,0,0]) split_clamp_sq(40,40,thru=true);
        }
        translate([0,0,4]) cylinder(d=brgOD+0.2, h=26);   // asiento del rodamiento (press-fit)
        translate([0,0,-1]) cylinder(d=brgOD-10, h=6);    // hombro de apoyo
        // agujeros de brida (M6) para atornillar al carro
        for(a=[0:60:359]) rotate([0,0,a]) translate([brgOD/2-4,0,-1]) bolt_hole(M6,8);
    }
}

// ---------- selector ----------
if(part=="elbow")      elbow();
else if(part=="clamp") split_clamp_sq();
else if(part=="vest")  vest_plate();
else if(part=="hub")   hub_clamp();
else if(part=="all"){
    elbow();
    translate([120,0,0]) split_clamp_sq();
    translate([-120,0,0]) hub_clamp();
    translate([0,320,0]) scale(0.6) vest_plate();
}
