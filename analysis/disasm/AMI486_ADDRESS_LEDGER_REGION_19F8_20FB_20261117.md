# AMI486 address-ledger extension: POST chipset profiles, option-ROM scan and protected-mode memory probe setup

Date: 2026-11-17  
Source: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Scope: `19F8h–20FBh`, with the continuation at `20FCh` included to establish the exact boundary.

## 1. Why this gap was selected

The current candidate mask left `19F8h–20FFh` uncovered (1,800 bytes), even though this region contains direct callers, a selector-table target, stack-threaded continuations and a protected-mode transition. Linear decode alone is misleading because multiple words are return addresses placed on the stack before jumping into shared CMOS/chipset helpers.

Direct near references into this region, normalized to 16-bit IP, include:
- 1240h -> 1C4Eh; 12A9h -> 1C4Fh; 12DFh -> 1C50h; 12E9h -> 1C5Eh.
- 1397h/1776h -> 1E73h; 13E0h -> 1E9Ah; 1402h -> 1E9Dh; 14B2h -> 1E78h; 14DEh -> 1E99h.
- 156Ah -> 1EC8h; 15CBh -> 2065h; 1608h -> 1F47h; 162Ch -> 203Fh; 1640h -> 2042h.
- 17ADh -> 1E4Bh; 17E2h -> 1E5Fh; 3F53h -> 19FBh.
- 5216h -> 1C05h; 52A1h -> 1C06h; 5C7Dh -> 1B5Eh; 5DBEh -> 1B5Fh; 5E05h -> 1B60h; 5E20h -> 1BF6h.
- 850Eh -> 1A8Fh; 852Fh -> 1A90h; D82Ch -> 1AF8h; D9D9h -> 1AFBh.

Additional control-flow evidence:
- CMOS 8Fh jump table at D6A8h, selector 7 -> 1B5Bh.
- 1B04h contains stack return word 1B06h; 1B2Ah contains stack return word 1B2Ch.
- 1B58h jumps to 208Dh.
- 2096h, 20C2h, 20CCh, 20D8h and 20FAh contain stack return words for 2098h, 20C4h, 20CEh, 20DAh and 20FCh.

## 2. Byte classification and entry boundaries

| Range | Classification | Evidence / role |
|---|---|---|
| 19F8h–19FAh | CR/LF/NUL terminator | Completes the CPU-clock display string block ending before 19FBh |
| 19FBh–1A8Eh | Code | Cache-size and CPU-speed display; AUTO Config gate; conditional ALi indexed-register writes |
| 1A8Fh | RET stub | Direct CALL target from 850Eh |
| 1A90h–1AF7h | Code | ALi 12h/13h and E017h adjustment; C000h option-ROM signature gate; returns at 1AF7h |
| 1AF8h–1AFAh | Code | JMP D82Fh; direct target of D82Ch |
| 1AFBh–1B03h | Code | MOV AL,B3h; prepares SP=1B04h; JMP EE94h to read CMOS B3h; direct target of D9D9h |
| 1B04h–1B05h | Stack-return word | Value 1B06h, consumed by CMOS helper RET |
| 1B06h–1B29h | Code continuation | Selects one of two ALi word lists at 8E4Eh–8E61h or 8E76h–8E79h, then writes selected words through 8DDCh |
| 1B2Ah–1B2Bh | Stack-return word | Value 1B2Ch, consumed by 8DDCh |
| 1B2Ch–1B5Ah | Code continuation | Completes list loop, programs PIT/port 61h, fills 1,024 bytes through ES:DI, and jumps to 208Dh |
| 1B5Bh–1B5Dh | Code | JMP D724h; confirmed selector-7 target from D6A8h |
| 1B5Eh / 1B5Fh | RET stubs | Separate direct CALL targets from 5C7Dh and 5DBEh |
| 1B60h–1BB2h | Code | Applies optional handlers 2420h/242Bh/2436h; checks C000:0000 option-ROM signature and scans E000h–E800h if absent |
| 1BB3h–1BF5h | Code | Option-ROM header/size/checksum scanner; valid ROM is far-called at segment:0003h and resumes at 1BE7h |
| 1BF6h–1C04h | Code | Checks CS:B51Dh and conditionally calls 2415h; direct CALL target from 5E20h |
| 1C05h | RET stub | Direct CALL target from 5216h |
| 1C06h–1C4Dh | Code | Calls CS:82DEh hook; conditionally restores CMOS 95h–98h; calls 1836h/184Ah; refreshes timing category through 8F12h/25C4h and stores at DS:00E6h |
| 1C4Eh / 1C4Fh | RET stubs | Direct CALL targets from 1240h and 12A9h |
| 1C50h–1C5Dh | Code | ALi register 13h read/modify/write helper |
| 1C5Eh–1C71h | Code | Calls CS:82E2h hook, reads CMOS 8Eh, branches to 1DD3h when bits C0h are set |
| 1C72h–1C84h | Code continuation | AUTO Config gate and branch to chipset-profile path at 1C85h |
| 1C85h–1DD2h | Code | CMOS/ALi indexed-register read-modify-write sequence |
| 1DD3h–1E35h | Code | Feature-gated POST chipset path; checks CS:8256h and B51Bh/B517h, conditionally invokes 8BA3h/8B5Eh, writes C503h |
| 1E36h–1E4Ah | Interrupt-handler candidate | Checks DS:0012h bit 20h; if set jumps to F068h, else sends master-PIC EOI and IRETs; IVT installation unresolved |
| 1E4Bh–1E5Eh | Code | Sets bit 1 in ALi register 14h; direct CALL target from 17ADh |
| 1E5Fh–1E72h | Code | Clears bit 1 in ALi register 14h; direct CALL target from 17E2h |
| 1E73h–1E77h | Code | Returns AL=1 with OR-generated flags; direct callers 1397h/1776h |
| 1E78h–1E98h | Code | Tests CS:B513h and conditionally sets ALi register 14h bit 3; direct CALL target from 14B2h |
| 1E99h | RET stub | Direct CALL target from 14DEh |
| 1E9Ah–1E9Ch | Code | OR SP,SP; RET flag helper; direct CALL target from 13E0h |
| 1E9Dh–1EC7h | Code | Optional B51Fh/B521h/B523h handlers 2420h/242Bh/2436h; direct CALL target from 1402h |
| 1EC8h–1F46h | Code | POST A1h CMOS B3h profile selection; uses 8E62h–8E75h or 8E7Ah–8E7Dh lists |
| 1F47h–203Eh | Code | POST A4h AUTO Config gate and ALi register 16h/19h/1Ah/12h/18h/1Ah RMW sequence |
| 203Fh–2041h | Code | OR SP,SP; RET flag helper; direct CALL target from 162Ch |
| 2042h–2064h | Code | Optional B525h/B527h handlers 2441h/244Ch; direct CALL target from 1640h |
| 2065h–2067h | Code | JMP E05Bh; direct JMP target from 15CBh |
| 2068h–206Dh | Data | Six-byte LGDT pseudo-descriptor: limit 0017h, 24-bit base 0F2070h |
| 206Eh–206Fh | Zero padding | Two bytes between pseudo-descriptor and GDT |
| 2070h–2087h | Data | Three 8-byte GDT entries: null; flat base-zero writable 32-bit 4-GiB data segment at selector 0008h; base-zero writable 64-KiB data segment at selector 0010h |
| 2088h–208Ch | Unresolved data | Five bytes 01 04 02 10 40; no consumer established |
| 208Dh–2095h | Code | Writes C5h to ALi register 03h, then stack-threads through 8DDCh |
| 2096h–2097h | Stack-return word | Value 2098h |
| 2098h–20C1h | Code continuation | Iterates 21 four-byte records at 8750h–87A3h; converts byte 0 from ASCII-offset form to ALi index, takes byte 3 as value, skips index 26h, writes through 8DDCh |
| 20C2h–20C3h | Stack-return word | Value 20C4h |
| 20C4h–20CBh | Code continuation | LOOP to 20A5h; on completion sets SP=20CCh and JMPs F66Ah |
| 20CCh–20CDh | Stack-return word | Value 20CEh |
| 20CEh–20D7h | Code continuation | Loads BX=0800h and stack-threads through EEEFh |
| 20D8h–20D9h | Stack-return word | Value 20DAh |
| 20DAh–20F9h | Code | Sets CR0.PE, loads GDT at CS:2068h, loads ES=0008h (flat 4-GiB data selector), writes 44h to ALi register 10h |
| 20FAh–20FBh | Stack-return word | Value 20FCh |
| 20FCh onward | Code continuation | Begins memory-alias test with MOV DL,FFh; first ES/operand-size-prefixed dword store begins at 20FEh |

## 3. POST B3h profile-selection path and stack-threaded list writer

D9D9h is an unconditional near JMP to 1AFBh (`E9 1F 41`, 16-bit IP target). At 1AFBh the BIOS loads AL=B3h, sets SP=1B04h and jumps to EE94h. The CMOS helper returns through the word at 1B04h, resuming at 1B06h.

The continuation tests CMOS B3h bits 2–3 and selects one of two lists:
- bit 2 set: SI=8E4Eh, CX=8E62h;
- bit 2 clear: SI=8E76h, CX=8E7Ah.

It computes the word count, reads each word with CS:LODSW, places return address 1B2Ch on the stack via SP=1B2Ah, and jumps to 8DDCh. The return resumes at 1B2Ch and loops until the list is exhausted. The stream then programs PIT channel 2 and port 61h, writes 1,024 bytes through ES:DI and jumps to 208Dh.

This is distinct from the later POST A1h B3h profile selection at 1EC8h documented in phase 39; the paths select different lists and must not be merged.

## 4. Option-ROM scanning and initialization

The helper at 1B60h applies optional board-specific handlers gated by CS:B51Fh, CS:B521h and CS:B523h. It checks for signature 55AAh at C000:0000. If present, it takes the success return at 1BB0h. If absent, it scans E000h through E800h in 80h-paragraph (2-KiB) increments using 1BB3h.

1BB3h disables interrupts, clears direction, sets DS to candidate segment BX, checks 55AAh at offset 0, reads the ROM-size byte at offset 2, derives next segment (size × 20h paragraphs) and checksum length (size × 200h bytes), and accepts only a zero checksum. For a valid image it constructs a far-call frame and executes segment:0003h using RETF; the ROM returns to 1BE7h, which restores BP/BX/ES/DS. Invalid signature advances BX by 80h paragraphs; checksum failure returns to the scanner. This establishes the legacy option-ROM header/checksum/init mechanism without implying every scanned segment contains a valid ROM.

## 5. GDT and memory-probe entry correction

The LGDT pseudo-descriptor at 2068h contains limit 0017h and base 0F2070h. The GDT at 2070h contains a null descriptor, a base-zero writable 32-bit 4-GiB data descriptor at selector 0008h, and a base-zero writable 64-KiB data descriptor at selector 0010h.

The code at 20DAh sets CR0.PE, loads the GDT, then loads ES=0008h. It prepares the return word at 20FAh and jumps through 8DDCh. The word at 20FAh is FC20h, so RET resumes at 20FCh, not 2100h.

At 20FCh the stream begins with MOV DL,FFh. The first memory instruction begins at 20FEh:
```asm
20FC  B2 FF                         MOV DL,FFh
20FE  26 66 C7 06 00 00 55 55 AA AA  ES: MOV DWORD PTR [0000h],AAAA5555h
2108  26 66 C7 06 00 01 FF FF FF FF  ES: MOV DWORD PTR [0100h],FFFFFFFFh
2112  26 66 81 3E 00 00 55 55 AA AA  ES: CMP DWORD PTR [0000h],AAAA5555h
211C  0F 85 67 00                    JNE 2187h
```

Thus 2100h is the opcode byte inside the prefixed instruction that starts at 20FEh, not an independent entry. The older note that decoded 2100h as a DS word store followed by two STOSB operations is withdrawn. The first pattern is a 32-bit write through ES to the flat segment, not a DS:[0000h] word write plus caller-dependent STOSB operations.

The setup chain into the probe is byte-confirmed:
`D9D9h -> 1AFBh -> 1B06h -> 1B2Ch -> 208Dh -> 2098h -> 20C4h -> 20CEh -> 20DAh -> 20FCh`.
The actual installed RAM map and the hardware meaning of ALi selector values remain unresolved; no physical RAM capacity is inferred.

## 6. Candidate-generator update and remaining work

The generator is extended with byte-aligned seeds for confirmed code entries/continuations and explicit data ranges for stack-return words, the LGDT pseudo-descriptor, GDT and unresolved bytes at 2088h–208Ch. The old 2100h seed is replaced by 20FCh; 2108h becomes the next aligned seed after the first prefixed dword store.

Remaining:
- runtime caller of D9D9h and broader D9DCh alternate continuation;
- consumer of 2088h–208Ch;
- exact behavior of F66Ah and EEEFh in this stack-threaded chain;
- live installation source of the 1E36h IRET handler;
- hardware meaning of the B3h-selected lists.

This is a bounded address-ledger extension, not a whole-ROM semantic completion claim.
