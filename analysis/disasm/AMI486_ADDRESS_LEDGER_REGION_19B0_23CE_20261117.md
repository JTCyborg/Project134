# AMI486 address-ledger extension: POST cache, ALi configuration, option-ROM scan and A20/protected-mode probe

Date: 2026-11-17  
Source: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

## 1. Scope and result

The former candidate-mask gap 19F8h–20FFh is now covered by aligned code windows and explicit data ranges. The interval is not a single routine: it contains cache/CPU-speed display, CMOS-selected ALi1429 profile programming, option-ROM scanning, several POST chipset paths, an A20/8042 feature probe, a 21-record ALi table walker and a protected-mode memory-address test.

This map reconciles existing semantic reports (phases 16–35 and 38–39) with the current ROM bytes. It retains stack-return trampolines and alternate entries as separate views. The candidate windows are inspection windows, not a complete control-flow graph.

## 2. Cache and CPU-speed display (19B0h–1AFBh)

### 2.1 Data tables and labels

- 19B0h–19C1h: nine 16-bit cache-size values; the final word at 19C0h is zero and is not selected by the observed mask.
- 19C2h–19C9h: eight CPU-speed lookup bytes: `10 14 19 21 28 32 42 20`.
- 19C9h–19DBh: “ KB CACHE MEMORY” followed by CR/LF/NUL. The leading space at 19C9h is also the final byte of the preceding speed table; preserve the overlapping data interpretation.
- 19DCh–19EBh: “MHz CPU Clock” followed by CR/LF/NUL.
- 19ECh–19FAh: “MHz DX2 CPU ” followed by CR/LF/NUL. The 19F8h–19FAh bytes are the CR/LF/NUL suffix.

### 2.2 Executable paths

- 19FBh–1A23h reads ALi register 18h. If the cache-enable bit is set, it extracts the cache-size index, reads the word table at 19B0h, formats the value and prints the cache label at 19C9h.
- 1A24h–1A5Fh is the CPU-speed display path. It uses the lookup bytes at 19C2h and the CPU-clock strings. The CMOS B6h.0 AUTO Config gate is checked through 29EDh; the conditional branch selects the chipset-dependent speed display path.
- 1A60h–1A8Fh is the conditional ALi initialization path selected by CMOS B6h.0. It checks the current ALi state and applies the associated register updates.
- 1A90h–1AFAh reads ALi registers 12h/13h and normalizes the BIOS-reported memory-size value at E017h. This is a memory-size normalization routine; it is not itself a write to the ALi registers.

## 3. CMOS B3h profile selection and table writes (1AFBh–1B5Dh)

### 3.1 First stack-return trampoline

At 1AFBh the code loads AL=B3h, sets SP=1B04h and jumps to EE94h (CMOS indexed read). The word at 1B04h–1B05h is 1B06h, so RET from EE94h resumes at 1B06h.

The continuation tests CMOS B3h bits 2/3 and selects one of the two small profile tables at 8E4Eh or 8E76h. This is the B3h-selected profile table; it is distinct from the later 21-record table at 8750h–87A4h.

### 3.2 Second stack-return trampoline

At 1B20h the code sets SP=1B2Ah and jumps to 8DDCh, the ALi indexed-register writer. The word at 1B2Ah–1B2Bh is 1B2Ch, so the helper returns to the loop at 1B2Ch.

The loop applies the selected profile words through 8DDCh, programs port 61h, port 8Fh, PIT control/data ports 43h/41h, fills 400h bytes at ES:DI, then jumps to 208Dh for the separate 8750h table pass.

The one-byte RET stubs at 1B5Eh and 1B5Fh are preserved as code entries; they are not part of the PIT loop.

## 4. Option-ROM scan and C0000h window path (1B60h–1C05h)

### 4.1 E0000h–E7FFFh scan

1B60h selects ALi index C503h, then checks the option keys at CS:B51Fh, B521h and B523h through 8300h. When enabled, it calls the corresponding ROM-window helpers 2420h, 242Bh and 2436h.

It then checks C000:0000 for signature AA55h. If no image is present, BX scans E000h up to (but not including) E800h. The invalid-candidate helper at 1BF0h adds 0080h to BX, restores DS and returns. The validator at 1BB3h checks AA55h, reads the declared image size, verifies the checksum, and far-calls the option-ROM entry at segment:0003h. A valid image advances by its declared size rather than by a fixed 2-KiB step.

### 4.2 Separate C0000h path

1BF6h is a separate hook path reached from the POST 5E20h site. It reads CS:B51Dh through 8300h and conditionally calls the C0000h window helper. It is distinct from the E0000h–E7FFFh scan.

## 5. POST chipset configuration and A20 feature decision (1C06h–1F46h)

### 5.1 Stock callback slots and CMOS 8Eh gate

- 1C06h calls the pointer at CS:82DEh. The stock value is 19ADh (RET), so this callback is a no-op in the stock image. The routine then checks CS:8280h bit 40h and performs the associated ALi register setup when enabled.
- 1C50h is the ALi register 13h helper.
- 1C5Eh calls the pointer at CS:82E2h. The stock value is 19AEh (RET), also a no-op. It then reads CMOS 8Eh; bits C0h gate the normal configuration path.
- 1C72h calls 29EDh to test CMOS B6h.0. AUTO Config calls 8F12h, 2588h and 25A6h. The manual configuration continuation begins at 1C83h; its first CMOS key load is at 1C85h.

### 5.2 Manual CMOS-to-ALi1429 path

1C83h–1DD7h is the manual read/modify/write continuation. It reads the selected CMOS keys, combines them with the current ALi register values, and writes the resulting values through the indexed helpers at 8DCFh/8DDCh. This path is distinct from the later A4h configuration group at 1F47h.

### 5.3 Fast Gate A20 input-port probe

1DD8h–1E17h checks CS:8256h and the B51Bh option selector, then calls F5D9h to read the 8042 input port using command C0h. This is a detection/feature-selection step. It does not itself perform the A20 output-port write.

The actual A20 output-port operations are separate: F66Ah writes D1h/DFh to enable A20, and F66Eh writes D1h/DDh to disable it.

### 5.4 Conditional POST handlers

- 1DE8h is an internal continuation of the 1DD8h feature path; it calls 8300h for the B51Bh option record and updates the BDA state before the 8042 input-port probe.
- 1E37h–1E45h checks BDA 0012h bit 20h and routes to the appropriate continuation.
- 1E46h–1E4Ch is a short PIC EOI/IRET stub.
- 1E4Dh and 1E61h are ALi register 14h update helpers.
- 1E78h checks B513h through 8300h; when enabled it sets bit 3 in ALi register 14h.
- 1E9Ah–1E9Ch is an `OR SP,SP; RET` status-success stub.
- 1E9Dh checks B51Fh/B521h/B523h through 8300h and conditionally calls 2420h/242Bh/2436h for the shadow-window setup.

### 5.5 POST A1h and A4h paths

- 1EC8h–1F46h is the POST A1h wrapper. It saves/restores DS/ES/BP around 2850h, clears BDA 0016h bit 4, calls the gated memory-test/sizing path at 26F9h, reads CMOS B3h and writes the checkpoint value to port 80h.
- 1F47h–203Eh is the POST A4h AUTO/manual configuration handler. AUTO Config calls 8F12h, 2588h and 25A6h. Manual mode reads CMOS 46h, 49h, 55h, 42h, 48h, 4Ah and 57h and updates ALi registers 16h, 19h, 25h, 12h, 18h, 1Ah and 27h.
- 203Fh–2041h is the `OR SP,SP; RET` status-normalization stub.
- 2042h–2064h is the additional POST shadow-window/ALi configuration handler. It checks B525h/B527h and invokes the corresponding window helpers.

## 6. Reset stub, descriptor block and 21-record ALi table (2065h–20C8h)

- 2065h–2067h is a near-JMP stub to the reset entry F000:E05Bh.
- 2068h–208Ch is a descriptor/parameter block used by the protected-mode probe. The six-byte pseudo-descriptor at 2068h is loaded by `LGDT CS:[2068h]` at 20E3h; its raw limit is 0017h and its raw base is 930F2070h. The exact purpose of all adjacent descriptor bytes remains open.
- 208Dh–20C8h selects ALi index C503h and walks 21 four-byte records at 8750h–87A4h. It subtracts 30h from each record's low byte, skips entries whose adjusted value is 26h, and writes the selected values through 8DDCh. This 21-record table is independent of the B3h-selected 8E4Eh/8E76h profile tables.

The table walker uses stack-return trampolines:
- SP=2096h / JMP 8DDCh returns at 2098h.
- SP=20C2h / JMP 8DDCh returns at 20C4h.

## 7. A20-bracketed protected-mode memory-address probe (20C9h–23CEh)

- 20C9h is a tail jump to F66Ah, enabling A20. The code sets SP=20CCh first; the word at 20CCh–20CDh returns to 20CEh after the helper.
- 20CEh prepares the next indexed write. It sets SP=20D8h and jumps to 8DDCh; the return word at 20D8h–20D9h resumes at 20DAh.
- 20DAh reads CR0, sets PE, loads the GDT pointer at CS:2068h, and enters the protected-mode test using selector 4410h. It writes and verifies complementary 32-bit patterns at multiple offsets, derives the memory-address test result, and writes the result through ALi registers 10h/11h.
- 23BDh–23CAh clears CR0.PE and returns to real mode.
- 23CBh jumps to F66Eh to disable A20.
- 23CEh resumes the ordinary POST continuation.

This establishes the local A20/PE ordering and the 1B58h -> 208Dh -> 20C9h path. The upstream entry into the larger 1AFBh B3h profile block remains unresolved; no conventional direct CALL/JMP to its start has been established.

## 8. Data/stack ledger

| Range | Classification |
|---|---|
| 19B0h–19C1h | Nine-word cache-size table |
| 19C2h–19C9h | Eight-byte CPU-speed table |
| 19C9h–19DBh | Cache label plus CR/LF/NUL; overlaps the final speed-table byte |
| 19DCh–19EBh | CPU clock label plus CR/LF/NUL |
| 19ECh–19FAh | DX2 CPU label plus CR/LF/NUL |
| 1B04h–1B05h | Stack return word 1B06h |
| 1B2Ah–1B2Bh | Stack return word 1B2Ch |
| 2068h–208Ch | LGDT pseudo-descriptor and adjacent descriptor/parameter bytes |
| 2096h–2097h | Stack return word 2098h |
| 20C2h–20C3h | Stack return word 20C4h |
| 20CCh–20CDh | Stack return word 20CEh |
| 20D8h–20D9h | Stack return word 20DAh |

The separate RET stubs at 1B5Eh/1B5Fh and 1C4Eh/1C4Fh, plus the 1E9Ah status stub and 203Fh status stub, are classified as code rather than data.

## 9. Remaining uncertainties

- The upstream entry that first reaches the 1AFBh B3h profile trampoline and the larger 1B20h profile loop is still unresolved.
- The precise board-specific meanings of ALi registers 03h, 10h and 11h remain unnamed.
- The exact purpose of the full descriptor/parameter block at 2068h–208Ch, beyond the six-byte LGDT pseudo-descriptor, remains open.
- The precise external caller of the 20C9h memory-address probe is not identified, although its local entry from the 1B58h -> 208Dh sequence is confirmed.
- The semantics of each 8E4Eh/8E76h profile word remain in the separate B3h table analysis.

## 10. Candidate-mask result

The latest successful generator run covers the former 19F8h–20FFh gap completely: **no uncovered bytes remain in that interval**. The global candidate mask contains 597 code windows and 153 data ranges, covering 46,985/65,536 bytes (71.69%) with 121 overlap bytes, 66 uncovered intervals, 210 pages touched and 135 fully covered pages.

This is a seeded code/data inspection mask, not a whole-ROM semantic-completion percentage. The next largest uncovered interval is CA16h–D0FFh (1,770 bytes).
