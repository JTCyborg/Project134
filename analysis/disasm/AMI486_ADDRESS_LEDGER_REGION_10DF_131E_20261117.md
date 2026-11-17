# AMI486 address ledger — POST 8042/CMOS/video initialization 10DFh–131Eh

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Entry and boundaries

The 576-byte uncovered interval 10DFh–131Eh is a POST hardware-initialization continuation. No direct relative CALL/JMP target to 10DFh was found; the entry may be indirect or stack-threaded and remains an explicit boundary question.

The first bytes decode linearly as 00 B0 (ADD byte [BX+SI],DH), F4 (HLT), then the coherent POST sequence beginning at 10E2h. Do not silently discard the first three bytes or assert an independently verified caller. The candidate window is bounded through 1320h so that the near CALL beginning at 131Dh (target 135Ah) is complete across the old gap boundary.

## 2. 8042 keyboard-controller initialization and self-test

The sequence emits POST 80h, calls 90B3h, then checks CS:8280h bit 10h to choose a controller command-byte value (4Dh or 6Ch). It sends command 60h and the selected byte through F651h, then drains pending controller output through 1870h.

It polls status port 64h and drains port 60h as needed. It then:
1. Sends keyboard reset command FFh through F5C9h and expects acknowledgement FAh.
2. Reads the following response through F5F9h and expects self-test result AAh.
3. On failure, calls 8662h, records an error bit in BP, and tests the controller interface through F5BCh with command ABh.
4. Emits POST 81h and selects a second controller command-byte value (45h or 65h) based on the keyboard status/configuration bits.
5. Initializes the BIOS keyboard ring-buffer pointers at BDA:001Ah/001Ch and the buffer start/end fields at BDA:0080h/0082h.
6. Updates the master PIC mask at port 21h and checks status port 64h bit 4, recording a further BP error flag if the expected state is absent.

The helper implementations are cross-referenced in the F5AEh–F8E6h ledger; do not duplicate or replace their bounded wait behavior.

## 3. CMOS and memory-configuration validation

The POST code reads and writes CMOS through EE94h (read selected CMOS register using ports 70h/71h) and EE9Dh (write selected CMOS register). It also uses 16D1h to read paired CMOS values.

It checks CMOS register 8Eh status bits, compares CMOS memory-size/configuration fields (including 95h/96h and B0h/B1h-related values) with the BDA conventional-memory size, and updates CMOS fields when the ROM's validation path requires it. BP is used as a bitmask of detected controller/configuration problems. Additional CMOS values are normalized through EE94h/EE9Dh, including the B3h configuration field.

The exact meaning of every CMOS byte is not inferred from its index alone; the established behavior is that these values are compared against BIOS memory/configuration state and can set the Setup-warning flags.

## 4. I/O resource enumeration and Setup warning

The code writes 1414h to BDA:0078h and calls 16DAh to enumerate the four-entry I/O-resource table at CS:8248h. If BP contains any error bits, it calls 1656h. That helper displays "RUN SETUP UTILITY" and "Press <F1> to RESUME" and waits for F1.

When the warning path is not taken, the sequence continues through 1714h for the POST diagnostic display path. POST progress values 82h–8Eh are emitted during this part of initialization.

## 5. Video and chipset initialization

The later half of the block:
- calls 1C4Eh for chipset/shadow configuration;
- calls F104h when the relevant BDA flag is set;
- reads the equipment word through INT 11h;
- reads CMOS configuration through EE94h and selects the BIOS video mode;
- invokes INT 10h to set the selected mode;
- calls 1C4Fh, 1C50h and 1C5Eh for further chipset/POST configuration;
- waits through 5FD6h and, on the timeout path, resets the current video mode through 16B7h and displays the diagnostic text through 410Eh/F52Eh/F42Eh;
- displays the POST message at CS:7CA0h;
- checks CS:8280h bit 10h, reads CS:B50Bh through 8300h, and if the device/configuration path is present, installs offset 9712h at IVT address 0000:01D0h;
- emits POST F5h and calls 90B3h/9801h before POST 8Eh.

The CALL at 131Dh targets 135Ah, linking this sequence to the next POST continuation. The candidate limit was extended by one byte beyond the original interval to retain the complete three-byte CALL.

## 6. Important helper references

| Target | Role in this POST block |
|---|---|
| F651h | Write 8042 command 60h plus controller command byte |
| 1870h | Drain 8042 output buffer |
| F5C9h / F5F9h | Send keyboard reset and read ACK/self-test response |
| F5BCh | Send controller command and compare response |
| 8662h / 8649h | Record/clear POST error flags |
| EE94h / EE9Dh | CMOS read/write |
| 16D1h | Read paired CMOS values |
| 16DAh | Enumerate I/O resources |
| 1656h | Display Setup warning and wait for F1 |
| 1714h | POST diagnostic display/input path |
| 1C4Eh / 1C4Fh / 1C50h / 1C5Eh | Chipset/shadow/POST configuration |
| F104h | Conditional video/shadow path |
| 16B7h | Reset current video mode |
| 8300h | Configuration/device accessor |
| 90B3h / 9801h | Late POST hardware initialization |

## 7. Generator integration

The candidate generator now includes a bounded 10DFh POST continuation window and extends it through 1320h to include the complete CALL at 131Dh. No embedded data range is assigned within the 10DFh–131Eh interval; the first three bytes remain a documented entry-boundary uncertainty.

GitHub Actions run 44085575642 completed successfully. The manifest reports 826 candidate windows, 238 data ranges, 40,911 unique code-window bytes, 19,703 unique data-range bytes, 293 overlap bytes, and a 60,321-byte union (92.04%). There are 64 uncovered intervals; the next largest is 066Bh–084Eh (484 bytes).
