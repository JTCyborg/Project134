# AMI486 semantic map — phase 30 (2026-11-16)

## 1. INT 15h AH=87h: full A20 / protected-mode branch split

The AH=87h handler begins at 90E7h. The routine saves general registers and segment registers, enables A20 through 8ACFh -> F66Ah, saves the caller stack in the BDA (0040:0067/0069), constructs a temporary descriptor at DS:SI+8, loads a temporary GDT and IDT, and sets CR0.PE at 9139h–913Eh.

After entering protected mode, it loads DS=0010h and ES=0018h. The branch on CS:[8281h].6 at 9150h is a real alternate-mode selector:

### Bit 6 clear (ordinary transfer path)

- 9158h–915Fh performs REP MOVSD plus an optional MOVSW according to CX.
- It samples port 61h; if bits C0h are clear, it proceeds to restore the original descriptor tables and leave protected mode.
- 917Bh–9180h clears CR0.PE.
- 9191h calls 8AD2h -> F66Eh (8042 D1h, output-port value DDh; A20 disable).
- It updates CMOS index 0Fh and returns through 91A2h–91B1h, restoring DS, ES, registers and flags.

### Bit 6 set (alternate transfer/recovery path)

- 9156h branches to 91B4h, which uses REP MOVSW rather than the ordinary REP MOVSD path.
- It samples port 61h. If bits C0h are clear, it updates CMOS index 8Fh (writes 01h) and jumps to F068h.
- F068h checks the same CS:[8281h].6 bit. If set, it jumps to 8AD5h, which waits for the 8042 input buffer to become empty, sends command FEh to port 64h, then halts in a loop. This is a keyboard-controller CPU-reset pulse path, not an ordinary return to real mode.
- If the port-61h condition is nonzero, the routine enters 91DEh: it backs SI up four bytes, rewrites the two words at that location, calls EF36h, and tests AL.80h. The result selects AL=1 or AL=0; bit 6 then chooses the 91BCh alternate loop or the ordinary 9166h exit.
- The 91BCh loop repeats the word-copy operation and port-61h test; when the condition clears, it writes CMOS index 8Fh and again transfers to F068h.

Consequently, the bit-6 path must not be described as a normal AH=87h completion that simply restores A20 and returns. In the visible stock ROM, the bit-6 path is designed around the special reset/recovery route. The ordinary path is the one with the explicit CR0.PE clear and A20 disable followed by RETF 2.

## 2. AH=87h early failure and exceptional exits

- If the initial A20-enable helper returns nonzero at 90F3h, the branch at 90F8h goes to 90E4h/921Ah, sets POST checkpoint 03h and rejoins the common register restore at 91A2h. Since the enable helper reported failure, this route does not issue a compensating D1h/DDh write.
- If the port-61h check at 9160h or 91B6h detects bits C0h, the handler enters 91DEh and performs the recovery copy/check sequence.
- The 91D9h and 920Eh branches call 8AD2h (A20 disable) before the shared status/return logic.
- The 9211h call to F66Eh is an additional explicit A20-disable operation on one recovery branch.
- The common return at 91A2h can set CF from the saved status byte; do not infer success solely from reaching RETF 2.

## 3. Additional A20 caller: POST checkpoint 52h–58h

At 528Eh the POST path calls 8AD2h, which is a tail-jump alias to F66Eh and therefore writes D1h/DDh to disable A20. It then calls F66Eh again at 5291h. These are two consecutive disable requests, not an enable/disable pair.

The routine then continues through F419h, 1C06h, and 52C7h and into later POST work. The duplicate disable is present in the decoded byte stream; its necessity is not established. Keep it recorded as an observed redundant-looking operation rather than assigning an undocumented reason.

## 4. POST keyboard initialization also disables A20

At F47Eh, after keyboard-controller setup around F466h–F47Bh, BIOS calls F66Eh to write D1h/DDh. It then reads CMOS 8Eh and conditionally continues through 1410Eh and display/report routines.

This is a further independent caller of the A20-disable helper. It shows that A20 is forced to the BIOS's fixed disabled-output-port value during POST keyboard initialization; it is not merely toggled by protected-mode services.

## 5. Confirmed caller inventory for A20 helpers

The full linear disassembly contains these direct call sites:

- 528Eh -> 8AD2h -> F66Eh (disable); 5291h -> F66Eh (second disable).
- 90F3h -> 8ACFh -> F66Ah (enable) in INT 15h AH=87h.
- 9191h -> 8AD2h -> F66Eh (disable) on ordinary AH=87h exit.
- 91D9h -> 8AD2h -> F66Eh (disable) on recovery.
- 920Eh -> 8AD2h -> F66Eh (disable) on another recovery branch.
- 9211h -> F66Eh (disable) on the exceptional branch.
- 933Ch -> F66Ah (enable) in INT 15h AH=89h.
- F47Eh -> F66Eh (disable) in POST keyboard initialization.
- 20C9h and 23CBh are tail-jumps to F66Ah and F66Eh respectively, bracketing the protected-mode memory-address test/configuration sequence.

No other direct near CALL/JMP references to 8ACFh, 8AD2h, F66Ah or F66Eh were found in the full linear listing. This inventory is limited to direct references visible in the current linear decode; computed transfers and alternate instruction streams may add further callers.

## 6. Corrections and limits

- The 20C9h entry really is a jump to F66Ah; protected-mode setup begins at 20DAh. The earlier phase-29 description remains consistent with the byte stream.
- The normal AH=87h transfer path has a clear A20 enable/disable pair. The CS:[8281h].6 branch is a separate reset/recovery mode and must not be merged into that description.
- 8AD2h is only a trampoline to F66Eh; it does not implement a distinct controller protocol.
- F66Ah/F66Eh write fixed values DFh/DDh via 8042 command D1h. The ROM does not first read and preserve the complete previous output-port byte.

## 7. Remaining questions

- Determine the source/initialization of CS:[8281h].6 and whether the alternate AH=87h path can be activated in normal configurations.
- Identify the caller of the 20C9h memory-address test and establish what data structure/BIOS phase it belongs to.
- Trace the POST state surrounding 528Eh and F47Eh to determine why BIOS repeats the A20-disable write.
- Reconstruct computed/far control-flow edges to supplement the direct-call inventory.
