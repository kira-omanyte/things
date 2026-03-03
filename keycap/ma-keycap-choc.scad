// 間 (Ma) Keycap — Kailh Choc v1 Low-Profile
// A keycap with an embossed gate relief on the top face.
// 間 means "moonlight through a gate" — the gap IS the design.
// Subtractive design made physical.
//
// Kira Omanyte, 2026-03-03
// Profile: Low-profile flat (Choc-native)
// Compatibility: Kailh Choc v1 (PG1350) switches
// Print orientation: face-down (top surface on build plate for best finish)
//
// Dimensions sourced from:
//   - KeyV2 (rsheldiii): $choc_stem = [1.2, 3], spacing 5.7mm
//   - Kailh PG1350 datasheet
//   - CFX/MBK keycap references
//
// Addressing feedback on v1 (Cherry MX version):
//   1. No through-hole — gate is embossed (indented), not cut through
//   2. Embossed instead of raised — for finger feel
//   3. Proper Choc v1 stem — two rectangular posts
//   4. Print face-down for best top surface quality

$fn = 64;

// === Keycap Parameters ===

// Choc 1U keycap — MBK-style dimensions
cap_w = 17.5;        // width (mm) — MBK standard
cap_d = 16.5;        // depth (mm) — MBK standard
cap_h = 3.5;         // total keycap height (low profile)
wall = 1.2;          // wall thickness
corner_r = 1.0;      // corner rounding radius
top_inset = 0.5;     // how much the top face is narrower than bottom (per side)

// Top surface
dish_depth = 0.3;    // very gentle concavity
dish_radius = 60;    // large radius = subtle curve

// === Choc v1 Stem Parameters ===
// Two rectangular posts, not a cross
// Dimensions from KeyV2: [1.2, 3.0], spacing 5.7mm center-to-center
// The keycap has *sockets* (holes) that fit over the switch's posts
// Tolerances for FDM: posts on switch are 1.2 x 3.0
// Socket should be slightly larger for fit

stem_post_w = 1.2;       // switch post width (narrow dimension)
stem_post_l = 3.0;       // switch post length (long dimension)
stem_spacing = 5.7;      // center-to-center distance between posts
stem_slop = 0.15;        // tolerance (per side) — tighter than KeyV2's 0.35 for FDM
stem_socket_depth = 2.5; // how deep the socket goes into the keycap
stem_housing_w = 3.0;    // housing wall around each socket
stem_housing_l = 4.8;    // housing length around each socket

// Bridge between stem housings for rigidity
stem_bridge_w = 1.0;     // width of connecting bridge
stem_bridge_h = 2.0;     // height of bridge

// === Gate Design (間 — Embossed) ===
// The gate is embossed INTO the top surface — a tactile indentation
// Two vertical channels (the pillars) and a horizontal lintel channel
// The void between them — the untouched ridge — is the moonlight
// Compact and centered within the flat top surface area

gate_channel_w = 0.6;     // width of each embossed channel
gate_channel_depth = 0.35; // how deep the embossing goes (subtle)
gate_total_h = 5.0;       // total vertical span of the gate pattern
gate_pillar_spacing = 3.0; // distance between the two pillar channels (center-to-center)
gate_lintel_y = 1.8;      // y-offset of lintel from center (toward top of gate)
gate_lintel_w = 0.5;      // width of lintel channel
// Bounding: keep all embossing within an 8mm × 8mm area centered on the top face

// === Modules ===

// Rounded rectangle (2D profile)
module rrect(w, h, r) {
    offset(r) offset(-r) square([w, h], center = true);
}

// Keycap body — slightly tapered box
module keycap_body() {
    hull() {
        // Bottom face (wider)
        linear_extrude(0.01)
            rrect(cap_w, cap_d, corner_r);
        // Top face (slightly narrower)
        translate([0, 0, cap_h])
            linear_extrude(0.01)
                rrect(cap_w - top_inset * 2, cap_d - top_inset * 2, corner_r * 0.8);
    }
}

// Hollow interior — thins the walls, saves material
module keycap_hollow() {
    iw = cap_w - wall * 2;
    id = cap_d - wall * 2;
    iw_top = cap_w - top_inset * 2 - wall * 2;
    id_top = cap_d - top_inset * 2 - wall * 2;

    hull() {
        translate([0, 0, wall])
            linear_extrude(0.01)
                rrect(iw, id, corner_r * 0.5);
        translate([0, 0, cap_h - wall + 0.01])
            linear_extrude(0.01)
                rrect(iw_top, id_top, corner_r * 0.3);
    }
}

// Gentle dish on top surface
module dish() {
    translate([0, 0, cap_h + dish_radius - dish_depth])
        sphere(r = dish_radius);
}

// Single stem socket (the hole the switch post fits into)
module stem_socket() {
    sw = stem_post_w + stem_slop * 2;
    sl = stem_post_l + stem_slop * 2;

    translate([0, 0, -0.1])
        cube([sw, sl, stem_socket_depth + 0.2], center = true);
}

// Single stem housing (solid block around the socket)
module stem_housing() {
    cube([stem_housing_w, stem_housing_l, stem_socket_depth], center = true);
}

// Complete Choc stem assembly
module choc_stem() {
    translate([0, 0, wall + stem_socket_depth / 2]) {
        difference() {
            union() {
                // Left housing
                translate([-stem_spacing / 2, 0, 0])
                    stem_housing();

                // Right housing
                translate([stem_spacing / 2, 0, 0])
                    stem_housing();

                // Bridge between housings
                cube([stem_spacing - stem_housing_w + 0.1, stem_bridge_w, stem_bridge_h], center = true);
            }

            // Left socket
            translate([-stem_spacing / 2, 0, 0])
                stem_socket();

            // Right socket
            translate([stem_spacing / 2, 0, 0])
                stem_socket();
        }
    }
}

// Gate embossing — channels cut INTO the top surface
// The design: two vertical channels (pillar shadows) and a horizontal lintel
// What's LEFT between them — the untouched ridge — is the moonlight
// Intersected with a bounding volume to prevent cutting into side walls
module gate_emboss() {
    // Bounding box: only cut within the flat top surface area
    bound_w = cap_w - wall * 2 - top_inset * 2 - 1.0;
    bound_d = cap_d - wall * 2 - top_inset * 2 - 1.0;

    intersection() {
        // Bounding volume centered on top face
        translate([0, 0, cap_h - gate_channel_depth - 0.1])
            cube([bound_w, bound_d, gate_channel_depth + 2], center = true);

        // The actual gate channels
        translate([0, 0, cap_h - gate_channel_depth]) {
            // Left pillar channel (vertical)
            translate([-gate_pillar_spacing / 2, 0, 0])
                cube([gate_channel_w, gate_total_h, gate_channel_depth + 1], center = true);

            // Right pillar channel (vertical)
            translate([gate_pillar_spacing / 2, 0, 0])
                cube([gate_channel_w, gate_total_h, gate_channel_depth + 1], center = true);

            // Lintel channel (horizontal, near top)
            translate([0, gate_lintel_y, 0])
                cube([gate_pillar_spacing + gate_channel_w, gate_lintel_w, gate_channel_depth + 1], center = true);
        }
    }
}

// === Assembly ===

module ma_keycap_choc() {
    difference() {
        union() {
            // Shell: body minus hollow minus dish
            difference() {
                keycap_body();
                keycap_hollow();
                dish();
            }

            // Choc v1 stem
            choc_stem();
        }

        // Gate embossing (subtractive — cuts into top surface)
        gate_emboss();
    }
}

ma_keycap_choc();
