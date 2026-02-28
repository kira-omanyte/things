// 間 (Ma) Keycap — Cherry MX Compatible
// A keycap with a gate relief on the top face.
// 間 means "moonlight through a gate" — the gap IS the design.
// Subtractive design made physical.
//
// Kira Omanyte, 2026-02-28
// Profile: DSA-ish (low, uniform, slight spherical dish)
// Compatibility: Cherry MX / MX-clone switches
// Print orientation: right-side up (top face up, stem on build plate)

$fn = 64;

// === Parameters ===

// Keycap dimensions (1u)
unit = 18.1;         // 19.05mm pitch minus tolerance
top_width = 12.7;    // narrower top face (DSA-like)
height = 7.6;        // total keycap height
wall = 1.5;          // wall thickness
dish_depth = 0.6;    // spherical dish on top (gentle)
dish_radius = 40;    // large radius = gentle curve
corner_r = 1.0;      // corner rounding

// MX stem
stem_cross_w = 4.0;  // cross arm length (each direction from center)
stem_cross_t = 1.17; // cross arm thickness (tight fit)
stem_height = 3.6;   // socket depth
stem_outer = 5.6;    // outer cylinder of stem housing

// Gate design (間 — moonlight through a gate)
// The gate is oriented vertically on the keycap top face:
// two pillars rise from the surface, a lintel spans across,
// and a void cuts between and below them.
gate_void_w = 2.0;        // width of the central void (the moonlight)
gate_void_depth = 1.0;    // depth of the void cut into the cap
pillar_w = 2.2;            // width of each pillar
pillar_d = 1.0;            // depth (front to back) of each pillar
pillar_rise = 0.5;         // how much pillars rise above the cap surface
gate_h = 7.0;              // total gate height (vertical span on face)
lintel_h = 1.5;            // lintel thickness
lintel_rise = 0.35;        // lintel height above surface

// === Modules ===

// Rounded rectangle (2D)
module rrect(w, h, r) {
    offset(r) offset(-r) square([w, h], center = true);
}

// Keycap shell — tapered box with rounded corners
module keycap_body() {
    hull() {
        // Bottom face
        linear_extrude(0.01)
            rrect(unit, unit, corner_r);
        // Top face (narrower)
        translate([0, 0, height])
            linear_extrude(0.01)
                rrect(top_width, top_width, corner_r * 0.7);
    }
}

// Hollow interior
module keycap_hollow() {
    inner_bottom = unit - wall * 2;
    inner_top = top_width - wall * 2;

    hull() {
        translate([0, 0, wall])
            linear_extrude(0.01)
                rrect(inner_bottom, inner_bottom, corner_r * 0.5);
        translate([0, 0, height - wall + 0.01])
            linear_extrude(0.01)
                rrect(inner_top, inner_top, corner_r * 0.3);
    }
}

// Spherical dish on top (gentle concavity for finger feel)
module dish() {
    translate([0, 0, height + dish_radius - dish_depth])
        sphere(r = dish_radius);
}

// MX stem cross socket
module mx_stem() {
    translate([0, 0, wall]) {
        difference() {
            // Outer housing
            cylinder(d = stem_outer, h = stem_height);

            // Cross cutout (the socket that grips the switch)
            translate([0, 0, -0.1]) {
                cube([stem_cross_w, stem_cross_t, stem_height + 0.2], center = true);
                cube([stem_cross_t, stem_cross_w, stem_height + 0.2], center = true);
            }
        }
    }
}

// Internal support ribs
module support_ribs() {
    rib_t = 0.8;
    inner = unit - wall * 2;

    for (angle = [45, 135, 225, 315]) {
        rotate([0, 0, angle])
            translate([stem_outer/2 + 0.2, -rib_t/2, wall])
                cube([inner/2 - stem_outer/2 - 1, rib_t, stem_height]);
    }
}

// Gate — the 間 relief
// Two pillars and a lintel as additive geometry (rise above the surface)
// One void as subtractive geometry (cut below the surface)
module gate_additive() {
    total_w = pillar_w * 2 + gate_void_w;

    translate([0, 0, height - dish_depth]) {
        // Left pillar
        translate([-(gate_void_w/2 + pillar_w/2), 0, 0])
            linear_extrude(pillar_rise)
                rrect(pillar_w, gate_h, 0.3);

        // Right pillar
        translate([(gate_void_w/2 + pillar_w/2), 0, 0])
            linear_extrude(pillar_rise)
                rrect(pillar_w, gate_h, 0.3);

        // Lintel (spans across top of gate)
        translate([0, gate_h/2 - lintel_h/2, 0])
            linear_extrude(lintel_rise)
                rrect(total_w, lintel_h, 0.2);
    }
}

module gate_subtractive() {
    // The void — the moonlight — cuts down into the cap
    translate([0, -lintel_h/2, height - gate_void_depth]) {
        // Main channel
        cube([gate_void_w, gate_h - lintel_h, gate_void_depth + 1], center = true);

        // Slight flare at the bottom of the gate (light spreads)
        translate([0, -(gate_h - lintel_h) * 0.35, 0])
            cube([gate_void_w * 1.3, (gate_h - lintel_h) * 0.2, gate_void_depth + 1], center = true);
    }
}

// === Assembly ===

module ma_keycap() {
    difference() {
        union() {
            // Main shell with dish
            difference() {
                keycap_body();
                keycap_hollow();
                dish();
            }

            // MX stem
            mx_stem();

            // Support ribs
            support_ribs();

            // Gate pillars + lintel (additive)
            gate_additive();
        }

        // Gate void (subtractive)
        gate_subtractive();
    }
}

ma_keycap();
