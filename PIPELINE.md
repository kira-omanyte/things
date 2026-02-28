# 3D Printing Pipeline — OpenSCAD → Creality K1

## Overview

```
OpenSCAD (.scad) → openscad CLI (.stl) → PrusaSlicer CLI (.gcode) → Moonraker API → K1 prints
```

## Printer

- **Model:** Creality K1 (hostname: K1-0BF7)
- **IP:** 192.168.0.68 (local network, reachable from container)
- **API:** Moonraker v0.10.0 on port 7125
- **Firmware:** Klipper
- **Build volume:** 220×220×250mm
- **Nozzle:** 0.4mm

## Step 1: Design (OpenSCAD)

Write parametric designs in `.scad` files. OpenSCAD is a code-based 3D modeler — no GUI needed.

```bash
# Example: 20mm calibration cube with embossed K
cat > my-design.scad << 'EOF'
$fn = 32;
difference() {
    cube([20, 20, 20], center = true);
    translate([0, 0, 9.5])
        linear_extrude(height = 1)
            text("K", size = 10, halign = "center", valign = "center");
}
EOF
```

## Step 2: Render to STL

```bash
openscad -o output.stl input.scad
```

Typical render time: < 1 second for simple geometry, minutes for complex `$fn` values.

## Step 3: Slice to Gcode

```bash
xvfb-run prusa-slicer --export-gcode \
  --load ~/.config/PrusaSlicer/creality-k1-flat.ini \
  -o output.gcode input.stl
```

### CRITICAL: Profile format

Use `creality-k1-flat.ini` (not `creality-k1.ini`). The flat version has no section headers. The slicer profile **MUST be flat key-value pairs** — no `[section:Name]` headers. PrusaSlicer's `--load` flag silently ignores settings inside section headers and falls back to defaults (which use bare `G28` instead of the K1's `START_PRINT` macro).

**Symptom of broken profile:** Gcode starts with `G28 ; home all axes` instead of `START_PRINT EXTRUDER_TEMP=... BED_TEMP=...`. This means no bed heating, no leveling, no purge line. Result: macaroni.

**Correct start gcode in output:**
```gcode
M140 S0
M104 S0
START_PRINT EXTRUDER_TEMP=220 BED_TEMP=55
```

The `START_PRINT` macro in the K1's Klipper config handles:
- Homing (`CX_ROUGH_G28`)
- Nozzle clearing (`CX_NOZZLE_CLEAR`)
- Accurate homing (`ACCURATE_G28`)
- Bed leveling (`CX_PRINT_LEVELING_CALIBRATION`)
- Purge line (`CX_PRINT_DRAW_ONE_LINE`)

### Key slicer settings (from profile)

| Setting | Value |
|---------|-------|
| Layer height | 0.2mm |
| First layer height | 0.2mm |
| Nozzle temp | 220°C |
| Bed temp | 55°C |
| Infill | 15% gyroid |
| Max print speed | 600mm/s |
| Perimeters | 2 |
| Top/bottom layers | 4/3 |

## Step 4: Upload and Print

```bash
# Upload gcode to printer
curl -s -X POST http://192.168.0.68:7125/server/files/upload \
  -F "file=@output.gcode" \
  -F "root=gcodes"

# Start print
curl -s -X POST http://192.168.0.68:7125/printer/print/start \
  -H "Content-Type: application/json" \
  -d '{"filename": "output.gcode"}'
```

## Monitoring

```bash
# Check print status
curl -s "http://192.168.0.68:7125/printer/objects/query?print_stats&virtual_sdcard&heater_bed&extruder"

# Check printer state
curl -s http://192.168.0.68:7125/printer/info

# Cancel print
curl -s -X POST http://192.168.0.68:7125/printer/print/cancel
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Macaroni / no adhesion | Cold bed — `START_PRINT` macro not called | Check gcode header for `START_PRINT`, verify flat profile format |
| No purge line | Same as above — default gcode doesn't include purge | Same fix |
| `G28 ; home all axes` in gcode | Profile has section headers `[printer:...]` | Strip section headers, use flat key-value format |

## Notes

- Printer must be physically turned on to be reachable
- `xvfb-run` is required for PrusaSlicer in headless container
- OpenSCAD `$fn` controls curve resolution — higher = smoother but slower render
- First successful print: Feb 28, 2026 — 20mm K-cube, ~12 min print time
