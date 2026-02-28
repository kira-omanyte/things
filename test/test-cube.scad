// Test cube — 20mm calibration cube
$fn = 32;

difference() {
    cube([20, 20, 20], center = true);
    
    // Letter "K" on top face — a simple marker
    translate([0, 0, 9.5])
        linear_extrude(height = 1)
            text("K", size = 10, halign = "center", valign = "center");
}
