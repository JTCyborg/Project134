# AMI486 address ledger — INT 09h keyboard IRQ body AF86h–B1E8h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Entry path and boundary

The IVT offset table installs E987h for INT 09h. E987h jumps to AF60h, where the keyboard IRQ path examines the keyboard-controller state and selects one of several continuations. The former uncovered interval begins at AF86h, which is the final displacement byte of the near JMP at AF84h.

The relevant branch entries are:
- AF84h: near JMP to B2E5h.
- AF87h: near JMP to B1DFh, the common keyboard IRQ exit.
- AF8Ah: near JMP to B1E4h, an alternate exit that skips the BDA flag clear.
- AF8Dh: main scan-code processing body.

The main body AF8Dh–B1DEh is 594 bytes. The two exit entries converge at B1DFh/B1E4h.

## 2. Keyboard state and special-key handling

The handler updates BIOS keyboard state bytes at low-memory offsets 0017h, 0018h and 0019h, and also uses 0072h as the warm-boot flag. The code is a keyboard IRQ scan-code path, not a general-purpose POST routine.

Established special cases:
- Scan code 54h: SysRq path. The handler checks the extended keyboard-state flag, sets the state bit, sends PIC EOI, and invokes INT 15h with AX=8500h (SysRq intercept).
- Scan code 53h with the required modifier flag in BDA:0017h: writes 1234h to 0000:0072h and jumps to F000:E05Bh, implementing Ctrl+Alt+Delete warm reboot.
- Scan code 46h and related state: updates the keyboard lock/status state and invokes the corresponding helper path.
- Scan code 37h: special PrintScreen path, including INT 05h when the required state bits are set.
- Scan code 1Ch and 35h: special Enter/keypad-slash handling.
- Extended E0/E1 prefixes and modifier state are tracked through BDA:0018h/0019h.
- Alt-numeric entry accumulates digits in BDA:0019h and later emits the translated character through the keyboard-buffer helpers.

The code also calls INT 1Bh for the Ctrl-Break path. The precise meanings of all auxiliary state bits at 0017h/0018h should be cross-checked against the B3D8h/B3D2h helper routines before implementing the full keyboard state machine.

## 3. Shared IRQ epilogues

B1DFh begins the common exit:
- ANDs BDA:0096h with FCh;
- disables interrupts;
- sends EOI 20h to PIC command port 20h.

B1E4h is an alternate entry beginning at CLI, skipping the BDA:0096h flag clear. Both paths converge on the continuation at B1E9h, which calls B26Ah, restores the saved stack/register frame and returns with IRET.

The short jumps at AF87h and AF8Ah select these two exit variants from the AF60h prelude.

## 4. Call and branch relationships

- IVT INT 09h → E987h → AF60h.
- AF60h branches to AF84h, AF87h, AF8Ah or falls through to AF8Dh depending on keyboard state.
- AF8Dh calls B3D8h, B25Fh, B253h, B3D2h, B3CCh, B26Ah, B1F5h, B20Eh and B221h for scan-code acquisition, state tests, translation and buffer insertion.
- AF87h → B1DFh.
- AF8Ah → B1E4h.
- B1DFh/B1E4h → common continuation at B1E9h.

The helper implementations at B1F5h/B20Eh/B221h/B253h/B25Fh/B26Ah/B3CCh/B3D2h/B3D8h are outside this interval and remain separately tracked. Their contracts should be confirmed before treating the scan-code state machine as fully understood.

## 5. Generator integration

The candidate generator now completes the split near-JMP at AF84h and adds bounded entries for AF87h, AF8Ah, AF8Dh, B1DFh and B1E4h. No data range is assigned within AF86h–B1E8h; the interval is executable code.

GitHub Actions run 44085161932 completed successfully. The manifest reports 825 candidate windows, 238 data ranges, 40,335 unique code-window bytes, 19,703 unique data-range bytes, 293 overlap bytes, and a 59,745-byte union (91.16%). There are 65 uncovered intervals; the next largest is 10DFh–131Eh (576 bytes).
