# AMI486 address ledger — BIOS Setup main menu 3C5Ch–3E3Eh

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Entry and layout

The 483-byte uncovered interval begins with two zero padding bytes at 3C5Ch–3C5Dh. The executable main-menu entry is 3C5Eh (PUSH BP / MOV BP,SP). A direct near-JMP from 2F21h enters 3C5Eh.

The routine ends with RET at 3E3Eh. The next function begins at 3E3Fh and is a shared menu/header renderer called from 3C75h and 3D9Dh.

## 2. Menu state and dispatch

The main loop maintains the selected menu index in CS:E187h and associated selection/display state in CS:E188h–E1A4h. It uses:
- Display-label pointer table at CS:342Eh–3445h (11 entries plus the separate final pointer at 3444h).
- Handler pointer table at CS:3446h–345Dh (12 near offsets).
- Menu title string at CS:345Eh: "BIOS SETUP UTILITIES".
- Shared drawing routines at 58A1h/58BEh/58C6h/58D3h and cursor/attribute helpers.

At 3D52h, the code computes twice E187h, loads the corresponding near handler offset from CS:3446h, and calls it indirectly. The candidate generator's handler table range was extended to 345Eh to include all 12 entries.

## 3. Twelve menu options and handlers

The descriptions are pointed to by the table at 342Eh/3444h; handler offsets are from 3446h–345Dh.

| # | Menu item | Handler offset |
|---:|---|---:|
| 0 | Standard CMOS Setup for changing time, date, hard-disk type, etc. | 00ECh |
| 1 | Advanced CMOS Setup for configuring system options | 0BDEh |
| 2 | Advanced CHIPSET Setup for configuring chipset registers | 0C05h |
| 3 | Power Management Setup for configuring power-management registers | 0C2Ch |
| 4 | Peripheral Management Setup for configuring peripheral registers | 0C53h |
| 5 | Load BIOS Setup defaults for Advanced CMOS and Advanced CHIPSET Setup | 5A7Ah |
| 6 | Load Power-On defaults for Advanced CMOS and Advanced CHIPSET Setup | 5A7Ah |
| 7 | Change the user password stored in CMOS | F1C8h |
| 8 | Auto detection of hard-disk type | 5038h |
| 9 | Format hard disk, auto interleave detection and media analysis | 4628h |
| 10 | Write settings to CMOS and exit | 2F67h |
| 11 | Do not write settings to CMOS and exit | 2F76h |

The two defaults options intentionally share handler 5A7Ah; the selected menu index remains available to the handler so it can distinguish the requested default set.

## 4. Navigation and selection

The loop polls keyboard input through 5AA2h and interprets BIOS key values/scan codes:
- 4Dh/50h/4Bh/48h: cursor navigation.
- 49h/51h: PageUp/PageDown selection movement.
- 0Dh: Enter/select.
- 1Bh: Escape/back path.

The movement helper at 3DF9h updates E187h, wraps the selection within the 12-item range and refreshes the highlighted item. 3D79h selects the current label pointer, updates the color/attribute at E19Fh and redraws the selected menu item. 3E24h resets selection state; 3E2Dh resets and moves to the final menu item.

The Enter path at 3D40h displays a warning/information page through 3D95h before continuing. The warning strings are:
- 34C1h: "WARNING INFORMATION"
- 34D5h: "Improper Use of Setup may Cause Problems !!"
- 3501h: "If System Hangs, Reboot System and Enter Setup by Pressing the <DEL> key"
- 354Ah: "Do any of the following After Entering Setup"
- 3577h: "(i) Alter Options to make System Work"
- 359Fh: "(ii) Load BIOS Setup Defaults"
- 35BEh: "(iii) Load Power-On Defaults"
- 35DBh: "Hit <ESC> to Stop now, Any other Key to Continue"

This is a warning/information screen, not merely a generic confirmation dialog.

## 5. Exit paths

The two final menu handlers are explicitly distinct:
- 2F67h writes settings to CMOS and exits.
- 2F76h exits without writing settings to CMOS.

Other menu handlers dispatch to the Standard/Advanced CMOS, chipset, power, peripheral, password, disk-detection and disk-formatting submenus/utilities.

## 6. Generator integration

The candidate generator now:
- classifies 3C5Ch–3C5Dh as two zero padding bytes;
- seeds 3C5Eh for 481 bytes through 3E3Eh;
- extends the Setup handler pointer table from 11 to 12 entries (3446h–345Dh).

The CI manifest is the verification gate for this menu loop and its table-boundary correction. The next largest uncovered interval will be taken from the completed run.
