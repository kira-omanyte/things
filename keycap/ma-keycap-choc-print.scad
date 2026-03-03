// Import and flip for printing — face-down orientation
// Top surface (embossed gate) on build plate for best finish
translate([0, 0, 3.5])
rotate([180, 0, 0])
import("ma-keycap-choc.stl");
