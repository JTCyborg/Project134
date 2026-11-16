# AMI486 keyboard BIOS subsystem — 2026-11-16

Source: ami486.bin (65,536 bytes), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b  
Decode: Capstone x86-16 seeded windows in ami486_candidate_windows_20261116.txt.

## 1. Data and entry regions

- AD00h–AE5Fh is keyboard translation data, not code. It contains scan-code/character mappings with recognizable QWERTY, ASDF, ZXCVBNM and numeric-key sequences. Exact subtable boundaries and modifier columns remain to be established.
- AE60h–AE6Ch is a wrapper that enables interrupts, calls 90B2h, saves registers, sets DS=0040h and jumps to 88CBh.
- AE6Fh onward is a scan-code processing path. It invokes BIOS INT 15h with AH=4Fh and processes the returned scan code and carry status.
- AEE3h onward is a branch-targeted continuation of that path; AF00h is not a safe entry boundary by itself.

## 2. Scan-code and modifier handling

### Prefix and special response state

The handler distinguishes:
- E1h prefix: sets bits 0 and 4 in BDA byte 0096h.
- E0h prefix: sets bits 1 and 4 in BDA byte 0096h.
- FEh and FAh: treated as keyboard-controller RESEND/ACK response states and recorded in BDA byte 0097h.
- FDh/FFh: routed through the common cleanup/acknowledgement path.

The code tests [0096h] bit 0 and bit 1 in B3D8h/B3D2h respectively, so those are explicit E0/E1 prefix-state tests.

### Modifier and lock-key masks

| Helper | Scan code | Bit returned in AH | Key |
|---:|---:|---:|---|
| B242h | 3Ah | 40h | Caps Lock |
| B242h | 45h | 20h | Num Lock |
| B242h | 46h | 10h | Scroll Lock |
| B253h | 38h | 08h | Alt |
| B253h | 1Dh | 04h | Ctrl |
| B253h | 2Ah | 02h | Left Shift |
| B253h | 36h | 01h | Right Shift |

B315h computes the desired keyboard LED mask from the BIOS shift-state byte at 0040:0017h and the tracked LED/controller state at 0040:0097h.

## 3. 8042 keyboard-controller operations

| Entry | Behavior |
|---:|---|
| B26Ah | Waits for the 8042 input buffer, writes AEh to port 64h (enable keyboard interface), then STI/RET |
| B273h | Waits for the input buffer, writes ADh to port 64h (disable keyboard interface), waits again, reads port 60h |
| B280h | Polls status port 64h bit 1 (input-buffer busy) with bounded loops |
| B327h | If LED state is dirty, sets state bit, sends EOI to PIC, then updates keyboard LEDs |
| B33Dh | Sends EDh (Set LEDs), sends the computed LED mask, optionally sends F4h (Enable Scanning), clears update state |
| B36Ah | Sends a keyboard command byte to port 60h, retries up to three times, and tracks ACK/RESEND state in 0097h |
| B296h | Sends master PIC EOI (20h to port 20h), then pulses bit 1 of port 61h with delay loops; this is the speaker/acknowledgement pulse path |

The command bytes EDh, F3h and F4h are used as keyboard protocol commands: Set LEDs, Set Typematic Rate/Delay, and Enable Scanning. The ADh/AEh writes target the 8042 command port 64h.

## 4. BIOS keyboard ring buffer

The code uses the standard BIOS Data Area keyboard-buffer fields:
- 0040:001Ah — buffer head
- 0040:001Ch — buffer tail
- 0040:0080h / 0040:0082h — buffer start/end

B399h advances a word pointer by two and wraps from [0082h] to [0080h]. B2C1h converts letter case according to modifier state, inserts the key word at the head, detects a full buffer, and updates the head. On overflow it calls B296h. The successful path sends PIC EOI, re-enables the keyboard interface and invokes INT 15h AX=9102h as a keyboard-input notification.

B4A9h waits for a key in the buffer, invokes INT 15h AX=9002h while empty, obtains the word at the tail and advances the tail. B4C7h handles F0h prefix cleanup; B4D5h normalizes E0h/F0h extended scan codes and selected special keys.

## 5. BIOS INT 16h service handler

B3E2h is an INT 16h handler entry candidate. It sets DS=0040h and dispatches AH:
- AH=00h -> B480h: wait/read keystroke path.
- AH=01h -> B48Ah: check-key path.
- AH=02h -> B473h: return shift flags from 0040:0017h.
- AH=03h -> B431h: set typematic rate/delay; validates BL/BH and AL=05h, disables keyboard, sends F3h plus parameter, re-enables keyboard and sends F4h.
- AH=05h -> B413h: insert CX into keyboard buffer; AL indicates full/success.
- AH=10h -> B478h: enhanced check/read normalization path.
- AH=11h -> B45Dh -> B49Ah: enhanced check path.
- AH=12h -> B45Fh: extended shift-state query assembled from BDA bytes 0018h, 0096h and 0017h.

The extended service subpaths B478h/B45Dh/B45Fh rely on B4C7h/B4D5h for E0h/F0h handling. The exact return-register and ZF contracts should be checked against all exits before treating this table as a full INT 16h specification.

## 6. Remaining questions

1. Determine the exact subtable boundaries and selector logic in AD00h–AE5Fh.
2. Identify the vector/caller that reaches the AE6Fh scan-code processing path and the wrapper at AE60h.
3. Resolve the meaning of BDA state bytes 0096h/0097h beyond the explicitly decoded prefix/ACK/LED bits.
4. Verify all INT 16h return flags/registers for AH=00h/01h/10h/11h/12h.
5. Trace how the INT 15h AH=4Fh result and CF determine whether the scan code is consumed or passed onward.

This report maps the keyboard data, 8042 protocol, BIOS ring buffer and INT 16h service paths. It does not claim the whole keyboard subsystem is complete.
