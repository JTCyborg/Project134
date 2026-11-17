# AMI486 address ledger — 8042, option-ROM, boot and BIOS interrupt services F5AEh–F8E6h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region layout

The former uncovered interval F5AEh–F8E6h is 825 bytes. It consists of small 8042 helpers, generic I/O test routines, option-ROM scanning, INT 19h boot logic, BIOS interrupt handlers and two small padding regions.

| Range | Classification |
|---|---|
| F5AEh–F5B1h | Four-byte opaque prefix; entry alignment unresolved |
| F5B2h–F5BBh | Port 61h control helper candidate |
| F5BCh–F5D8h | 8042 command/data readback helpers |
| F5D9h–F5F8h | Read 8042 output port via commands C0h and D0h |
| F5F9h–F621h | 8042 output-buffer wait/read helpers |
| F622h–F670h | 8042 command/data write and output-port helpers |
| F670h–F690h | 8042 output-port D1h command sequence |
| F691h–F6B7h | Generic I/O port write/read/compare helper |
| F6B8h–F6D8h | Four-pattern I/O port test |
| F6D9h–F723h | Option-ROM signature/length/checksum scan and initializer |
| F724h–F730h | INT 19h boot-failure fallback |
| F731h–F73Ah | Keyboard IRQ handler and chain |
| F73Bh–F757h | Boot-return stack-frame guard |
| F758h–F80Fh | INT 19h bootstrap and boot-sector validation |
| F810h–F82Bh | INT 13h sector-read retry helper |
| F82Ch–F840h | Zero-filled padding |
| F841h–F84Ch | INT 12h conventional-memory handler |
| F84Dh–F858h | INT 11h equipment-list handler |
| F859h–F85Bh | INT 15h near-JMP trampoline to 90B4h |
| F85Ch–F85Dh | Two-byte zero padding |
| F85Eh–F8E2h | INT 17h printer-service handler |
| F8E3h–F8E6h | INT 14h serial-service handler prologue |

## 2. 8042 keyboard-controller helpers

The helpers at F5BCh–F670h centralize status polling, command writes, data writes, output-port access and readback validation.

- F5BCh writes the supplied command through F635h, reads a response through F5F9h, and compares AL with AH.
- F5C9h writes data through F644h and performs the same readback comparison.
- F5D9h drains a pending output byte if present, issues command C0h and reads the 8042 output port.
- F5E9h does the corresponding operation with command D0h.
- F5F9h waits through F5FFh and reads port 60h.
- F5FFh performs a bounded poll of status port 64h for output-buffer state.
- F60Fh polls the output-buffer-full bit with an AH countdown and reads port 60h.
- F622h sends a command then a data byte, using F635h/F644h.
- F62Dh sends command D1h with the caller's AL value.
- F635h waits for input-buffer clear, writes AL to command port 64h, then waits again.
- F644h waits for input-buffer clear and writes AL to data port 60h.
- F651h sends command 60h and its data byte.
- F659h waits for input-buffer clear by polling status bit 2.
- F66Ah/F66Eh are alternate entries that send D1h with DFh/DDh respectively; F670h performs the command/data write sequence.

The short entry F5B2h writes a masked AL value to port 61h under PUSHA/POPA. No direct relative CALL xref was found. F5AEh–F5B1h remains an opaque prefix rather than being forced into this routine.

## 3. Generic I/O test and option-ROM scanner

F691h is a reusable port test primitive. It writes AL to DX, optionally emits FFh to POST port 80h, reads back from DX, compares with AH, and may perform a second read when BX is nonzero.

F6B8h invokes F691h with four test patterns:
- AA55h
- 55AAh
- CC0Fh
- 0000h

It returns the final comparison flags. Direct CALL targets found at 16F4h, AAFFh, E2E5h, E317h and E330h.

F6D9h is the option-ROM scanner, called from 13EDh, 1638h and 5E11h:
1. Saves DS, sets DS=BX and checks the 55AAh ROM signature at offset 0.
2. Uses the ROM size byte at offset 2 (with the E000h special case) to determine the scan length.
3. Sums the ROM bytes and rejects a nonzero checksum.
4. On success, performs a far transfer to the option-ROM initialization entry at segment BX, offset 0003h, with a return frame at F70Fh. It restores ES/BX/BP/DS after the option ROM returns.
5. On a bad signature, advances BX by 80h and returns; on checksum failure, sets BP=7 and jumps to F4A5h.

This confirms that the earlier POST scans over C800h–DFFFh and E000h–E7FFh execute option-ROM initialization only after signature and checksum validation.

## 4. Boot failure, keyboard IRQ and stack guard

F724h calls EF36h, invokes INT 19h, and if that returns emits POST AAh to port 80h before entering a STI/HLT loop.

F731h reads the keyboard data port 60h, sends EOI 20h to the master PIC command port 20h, then chains through the far pointer at BDA/low-memory offset 0067h.

F73Bh checks the caller's saved CS:IP against the expected CS:F7AFh return frame. If it matches, it discards six stack bytes and resumes at F7B2h. Otherwise it selects the boot error string at 7B15h and jumps to the F509h diagnostic display path.

## 5. INT 19h bootstrap and disk read retry

F758h is the INT 19h bootstrap target (the near-JMP at E6F2h):
- ES=0000h and the INT 1Eh vector at 0000:0078h is set to CS:EFC7h.
- The 7C00h boot-sector buffer is cleared.
- INT 13h reset is issued.
- The boot drive byte at CS:B516h is checked through the 8300h helper.
- F810h attempts to read sector 1 into the boot buffer.
- The 55AAh signature at ES:[BX+01FEh] is checked.
- A valid sector is transferred to 0000:7C00h after EF36h; an invalid or unreadable sector falls back through INT 18h and the displayed boot messages at 7B22h, 7B3Ah and 7B52h.

F810h performs up to four INT 13h reads (AH=02h, AL=01h). On failure it preserves AX, resets the disk with INT 13h AH=00h, restores AX, checks the status carry condition, and retries.

## 6. BIOS interrupt handlers installed by the IVT table

The IVT offset table mapped earlier provides these entries:
- INT 11h → F84Dh: calls 8B11h, then returns BDA:0010h equipment word.
- INT 12h → F841h: returns BDA:0013h conventional-memory size in AX.
- INT 14h → E739h → F8E3h: serial service dispatcher.
- INT 15h → F859h → 90B4h: system-service entry.
- INT 16h → E82Eh → B3DEh: keyboard service entry.
- INT 17h → EFD2h → F85Eh: printer service.
- INT 19h → E6F2h → F758h: bootstrap.
- INT 1Eh → EFC7h: diskette parameter table pointer installed again by the bootstrap.

F85Eh is the INT 17h printer-service handler. It obtains the selected LPT base from BDA:0008h+2×DX, checks the status port, writes the character, polls the busy/acknowledge bit, performs the required control-line sequence, and returns status in AH/AL. The two zero bytes at F85Ch–F85Dh are padding before this handler.

F8E3h is the INT 14h serial-service dispatcher. It validates DX<4 and AH<6, obtains the COM base from BDA:0000h+2×DX, loads a handler offset from CS:F92Ah indexed by AH, calls that handler, stores the returned AX in the interrupt frame, restores registers and IRETs. The six handler offsets in F92Ah–F935h are:
- F936h
- F986h
- F9C4h
- F977h
- F999h
- F9D3h

The serial dispatcher begins with STI/CALL 90B2h at F8E3h–F8E6h; the remainder is already represented by the existing F8E7h seed.

## 7. Candidate generator and coverage

The candidate generator now includes bounded seeds for the 8042 helpers, generic I/O tests, option-ROM scanner, INT 19h boot path, INT 11h/12h/14h/15h/17h handlers, and the zero-filled padding ranges. The E739h and EFD2h trampolines are recorded as separate code entries because the IVT table points to them.

GitHub Actions run 44084310128 completed successfully. The manifest reports 811 candidate windows, 237 data ranges, 39,090 unique code-window bytes, 18,912 unique data-range bytes, 293 overlap bytes, and a 57,709-byte union (88.06%). There are 68 uncovered intervals; the next largest is 7CE9h–7FFFh (791 bytes).

## 8. Next work

1. Continue with 7CE9h–7FFFh (791 bytes), the largest remaining uncovered interval.
2. Resolve the four-byte prefix F5AEh–F5B1h and the unreferenced port-61h entry F5B2h.
3. Trace the six INT 14h serial subhandlers at F936h/F977h/F986h/F999h/F9C4h/F9D3h.
4. Confirm whether the F731h chain pointer at 0067h is an IRQ1 predecessor or a BIOS keyboard hook.
5. Preserve the INT 11h/12h/14h/15h/16h/17h/19h vector relationships and the INT 1Eh DPT pointer in the independent implementation.
