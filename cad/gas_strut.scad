// ============================================================
//  OpenOmni - Resorte de gas (gas strut) PARAMÉTRICO
//  Modela el muelle neumático real + un CORTE que explica
//  cómo funciona por dentro. Unidades: mm.
//
//  part:
//   "assembly"  -> strut completo, extendido
//   "section"   -> MEDIO CORTE que revela el interior (educativo)
//   "compressed"-> corte con el vástago comprimido (gas comprimido)
//   "mount"     -> abrazadera impresa + ojal de acero (cómo se fija)
// ============================================================
part = "section";

// ---------- parámetros ----------
Lb      = 220;   // largo del cuerpo (tubo)
OD      = 24;    // diámetro exterior del cuerpo
wall    = 1.5;   // pared del tubo
ID      = OD-2*wall;
rod_d   = 10;    // diámetro del vástago
stroke  = 120;   // carrera del vástago
eye_od  = 18;    // ojal de montaje (exterior)
eye_bore= 8;     // perno M8
eye_th  = 8;     // espesor del ojal
$fn     = 80;

ext = (part=="compressed") ? 0.25 : (part=="section" ? 0.55 : 1.0);

// ------------------------------------------------------------
module eye(){                      // ojal de montaje con bore para perno
    difference(){
        union(){
            rotate([90,0,0]) cylinder(d=eye_od,h=eye_th,center=true);
            translate([0,0,-eye_od/2]) cube([eye_od,eye_th,eye_od/2+1],center=true);
        }
        rotate([90,0,0]) cylinder(d=eye_bore,h=eye_th+2,center=true);
    }
}

module strut(ext=1, cut=false){
    rod_out  = 40 + ext*stroke;              // cuánto sobresale el vástago
    pistonZ  = 20 + (Lb-55)*ext;             // pistón: alto si extendido, bajo si comprimido
    difference(){
        union(){
            // --- cuerpo: tubo de acero (hueco) + tapa inferior ---
            color("silver"){
                difference(){ cylinder(d=OD,h=Lb); translate([0,0,4]) cylinder(d=ID,h=Lb); }
                translate([0,0,-6]) cylinder(d=OD,h=8);
                translate([0,0,-6-eye_od/2]) eye();                 // ojal del cuerpo
            }
            // --- INTERIOR: como BLOQUES en la mitad y<0 (cara plana en y=0, sin z-fighting) ---
            gd = ID-0.8;                                   // ancho de las cámaras
            // gas N2 a presión (bajo el pistón)
            color([0.25,0.55,1.0]) translate([0,-gd/4,(4+pistonZ)/2]) cube([gd, gd/2, pistonZ-4], center=true);
            // pistón (émbolo con sello)
            color("black") translate([0,-gd/4,pistonZ+4.5]) cube([gd, gd/2, 9], center=true);
            // aceite (amortiguación, sobre el pistón)
            color([0.95,0.55,0.10]) translate([0,-gd/4,(pistonZ+9+Lb-12)/2]) cube([gd, gd/2, Lb-12-(pistonZ+9)], center=true);
            // orificio de paso del pistón (aceite -> amortiguación viscosa)
            color("yellow") translate([rod_d/2+2,-gd/4,pistonZ+4.5]) cube([2,gd/2,9], center=true);
            // --- vástago (unido al pistón, sale por arriba) ---
            color("gainsboro"){
                translate([0,-gd/4,(pistonZ+9+Lb)/2]) cube([rod_d, gd/2, Lb-(pistonZ+9)], center=true); // tramo interno
                translate([0,0,Lb]) cylinder(d=rod_d, h=rod_out);               // tramo externo
                translate([0,0,Lb+rod_out+eye_od/2]) rotate([0,180,0]) eye();   // ojal del vástago
            }
            // guía/sello superior del cuerpo
            color("dimgray") translate([0,0,Lb-12]) cylinder(d=OD-0.5, h=12);
        }
        if(cut) translate([0,OD,Lb/2]) cube([OD*3, OD*2, Lb*4], center=true);   // medio corte (quita y>0)
    }
}

// ---------- abrazadera impresa + ojal de acero (cómo se fija al brazo) ----------
module mount(){
    tube=32;               // tubo del brazo Ø32
    color("orange")
    difference(){
        union(){ cube([tube+16, tube+16, 22], center=true);
                 translate([0,-(tube+16)/2-3,0]) cube([tube+16,8,22],center=true); }
        cylinder(d=tube+0.4, h=30, center=true);                       // socket del tubo (+0.4 tol. FDM)
        cube([1.4, tube+24, 24], center=true);                         // ranura del split-clamp
        for(z=[-7,7]) translate([tube/2+5,-tube/2-3,z]) rotate([0,90,0]) cylinder(d=5.2,h=24,center=true); // pernos clamp M5
        rotate([90,0,0]) cylinder(d=8.2, h=tube+40, center=true);      // PERNO M8 pasante (el que aguanta)
    }
    color("dimgray") eye();                                            // ojal de acero del strut en el perno
}

// ---------- selector ----------
if(part=="assembly")        strut(1,false);
else if(part=="section")    strut(ext,true);
else if(part=="compressed") strut(ext,true);
else if(part=="mount")      mount();
