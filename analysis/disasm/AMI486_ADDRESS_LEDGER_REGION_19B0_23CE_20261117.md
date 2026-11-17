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
- 1A60h–1A8Eh is the conditional ALi initialization path selected by CMOS B6h.0. It checks the current ALi state and applies the associated register updates; 1A8Fh is a separate RET stub called from 850Eh.
- 1A90h–1AF7h reads ALi registers 12h/13h and normalizes the BIOS-reported memory-size value at E017h. This is a memory-size normalization routine; 1AF8h is a separate JMP trampoline to D82Fh, and 1AFBh is a distinct POST entry reached by D9D9h.

## 3. CMOS B3h profile selection and table writes (1AFBh–1B5Dh)

### 3.1 First stack-return trampoline

At 1AFBh the code loads AL=B3h, sets SP=1B04h and jumps to EE94h (CMOS indexed read). The word at 1B04h–1B05h is 1B06h, so RET from EE94h resumes at 1B06h.

The continuation at 1B06h tests CMOS B3h bits 2/3. If both are clear it skips the list writer and branches to 1B2Eh. If bit 2 is set it selects 8E4Eh–8E61h; otherwise (bit 3 set) it selects 8E76h–8E79h. This is distinct from the later 21-record table at 8750h–87A3h.

### 3.2 Second stack-return trampoline

At 1B24h the code sets SP=1B2Ah and jumps to 8DDCh, the ALi indexed-register writer. The word at 1B2Ah–1B2Bh is 1B2Ch, so the helper returns to the loop at 1B2Ch.

The loop applies the selected profile words through 8DDCh, writes port 61h and port 8Fh, programs PIT channel 1 (control word 54h to port 43h and count byte to port 41h), fills 400h bytes at ES:DI, then jumps to 208Dh for the separate 8750h table pass. The selector-7 entry at 1B5Bh is a separate JMP D724h target from the CMOS 8Fh table at D6A8h.

The one-byte RET stubs at 1B5Eh and 1B5Fh are preserved as code entries; they are not part of the PIT loop.

## 4. Option-ROM scan and C0000h window path (1B60h–1C05h)

### 4.1 E0000h–E7FFFh scan

1B60h selects ALi index C503h, then checks the option keys at CS:B51Fh, B521h and B523h through 8300h. When enabled, it calls the corresponding ROM-window helpers 2420h, 242Bh and 2436h.

It then checks C000:0000 for signature AA55h. If no image is present, BX scans E000h up to (but not including) E800h. The invalid-candidate helper at 1BF0h adds 0080h to BX, restores DS and returns. The validator at 1BB3h checks AA55h, reads the declared image size, verifies the checksum, and far-calls the option-ROM entry at segment:0003h. A valid image advances by its declared size rather than by a fixed 2-KiB step.

### 4.2 Separate C0000h path

1BF6h is a separate optional board-specific hook reached from the POST 5E20h site. It reads CS:B51Dh through 8300h and conditionally calls 2415h. Its exact hardware effect is not established by this local path.

## 5. POST chipset configuration and A20 feature decision (1C06h–1F46h)

### 5.1 Stock callback slots and CMOS 8Eh gate

- 1C06h calls the pointer at CS:82DEh. The stock value is 19ADh (RET), so this callback is a no-op in the stock image. The routine then checks CS:8280h bit 40h and performs the associated ALi register setup when enabled.
- 1C50h is the ALi register 13h helper.
- 1C5Eh calls the pointer at CS:82E2h. The stock value is 19AEh (RET), also a no-op. It then reads CMOS 8Eh; bits C0h gate the normal configuration path.
- 1C72h calls 29EDh to test CMOS B6h.0. If AUTO Config is active, this path calls 8F12h, 2537h and 256Ah, then jumps to 1CB5h. The manual configuration path is entered at aligned address 1C85h (1C83h is not an entry).

### 5.2 Manual CMOS-to-ALi1429 path

1C85h–1DD2h is the manual read/modify/write continuation. It reads the selected CMOS keys, combines them with current ALi register values, and writes through 8DCFh/8DDCh. The separate feature-gated entry at 1DD3h is reached by the direct JMP at 1C6Fh; it must not be merged into the manual stream.

### 5.3 Fast Gate A20 input-port probe

1DD8h–1E17h checks CS:8256h and the B51Bh option selector, then calls F5D9h to read the 8042 input port using command C0h. This is a detection/feature-selection step. It does not itself perform the A20 output-port write.

The actual A20 output-port operations are separate: F66Ah writes D1h/DFh to enable A20, and F66Eh writes D1h/DDh to disable it.

### 5.4 Conditional POST handlers

- 1DE8h is an internal continuation of the 1DD8h feature path; it calls 8300h for the B51Bh option record and updates the BDA state before the 8042 input-port probe.
- 1E36h–1E43h checks BDA 0012h bit 20h and routes to F068h when set.
- 1E44h–1E4Ah is the PIC EOI/IRET path: OUT 20h,20h followed by IRET.
- 1E4Bh and 1E5Fh are the aligned ALi register 14h set/clear helper entries.
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
- 2068h–206Dh is the six-byte LGDT pseudo-descriptor: limit 0017h, 24-bit base 0F2070h (byte 206Dh is the reserved high byte for 16-bit LGDT). 206Eh–206Fh are zero padding. The GDT at 2070h–2087h has three 8-byte entries: null, flat base-zero writable 4-GiB data selector 0008h, and base-zero writable 64-KiB data selector 0010h. Bytes 2088h–208Ch (`01 04 02 10 40`) remain unresolved.
- 208Dh–20C8h selects ALi index C503h and walks 21 four-byte records at 8750h–87A4h. It subtracts 30h from each record's low byte, skips entries whose adjusted value is 26h, and writes the selected values through 8DDCh. This 21-record table is independent of the B3h-selected 8E4Eh/8E76h profile tables.

The table walker uses stack-return trampolines:
- SP=2096h / JMP 8DDCh returns at 2098h.
- SP=20C2h / JMP 8DDCh returns at 20C4h.

## 7. A20-bracketed protected-mode memory-address probe (20C9h–23CEh)

- 20C6h sets SP=20CCh and jumps to F66Ah to enable A20; the word at 20CCh–20CDh returns to 20CEh after the helper.
- 20CEh loads BX=0800h, sets SP=20D8h and jumps to EEEFh; the return word at 20D8h–20D9h resumes at 20DAh.
- 20DAh reads CR0, sets PE, loads the GDT pointer at CS:2068h, then loads ES=0008h (the flat 4-GiB data selector). It loads AX=4410h as an ALi indexed-register write (index 10h, value 44h), not as a segment selector. After the 8DDCh helper returns through stack word 20FAh, execution resumes at 20FCh and begins the 32-bit ES memory-alias test.
- 20F4h sets SP=20FAh and jumps to 8DDCh; the word at 20FAh–20FBh is 20FCh. RET resumes at 20FCh, where MOV DL,FFh precedes the first prefixed dword store at 20FEh. The opcode byte at 2100h is inside that instruction, not a separate entry.
- The later 23BDh–23CAh continuation clears CR0.PE and returns to real mode; 23CBh jumps to F66Eh to disable A20; 23CEh–23CFh is a crafted stack-return word containing 23D0h; F66Eh returns to the 2-KiB 552Dh pattern test at 23D0h, whose RET resumes at 23DCh. The full continuation is mapped in `AMI486_ADDRESS_LEDGER_REGION_23CE_29F6_20261117.md`.

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
| 20D8h–20D9h | Stack return word 20DAh consumed by EEEFh |
| 20FAh–20FBh | Stack return word 20FCh consumed by 8DDCh |

The separate RET stubs at 1B5Eh/1B5Fh and 1C4Eh/1C4Fh, plus the 1E9Ah status stub and 203Fh status stub, are classified as code rather than data.

## 9. Remaining uncertainties

- D9D9h is a confirmed direct JMP to 1AFBh. The 1AFBh B3h profile trampoline and its 1B06h/1B2Ch stack-threaded continuation are therefore directly reachable; the earlier unresolved-entry statement is withdrawn.
- The precise board-specific meanings of ALi registers 03h, 10h and 11h remain unnamed.
- The GDT entries at 2070h–2087h are identified; only the five bytes at 2088h–208Ch remain unresolved.
- The precise external caller of the 20C9h memory-address probe is not identified, although its local entry from the 1B58h -> 208Dh sequence is confirmed.
- The semantics of each 8E4Eh/8E76h profile word remain in the separate B3h table analysis.

## 10. Candidate-mask result

The latest successful generator run covers the former 19F8h–20FFh gap completely: **no uncovered bytes remain in that interval**. The global candidate mask contains 597 code windows and 154 data ranges, 31,189 unique code-window bytes, 15,829 unique data-range bytes, 117 overlap bytes and a 46,901/65,536-byte union (71.57%), with 69 uncovered intervals, 210 pages touched and 133 fully covered pages. This remains an inspection mask, not semantic completion. The next largest uncovered interval is CA16h–D0FFh (1,770 bytes).

This is a seeded code/data inspection mask, not a whole-ROM semantic-completion percentage. The next largest uncovered interval is CA16h–D0FFh (1,770 bytes).


## 10. Extended-memory alias-test tail at 22F7h–2380h

The previous section identified the A20/PE transition and the later 2381h–23B8h stack-threaded ALi update chain. This addendum closes the intervening comparison sequence, including the 38-byte candidate-mask hole at 235Bh–2380h.

The code runs with ES=0008h, the flat base-zero data selector established earlier. The 66h/67h-prefixed absolute memory operations therefore access 32-bit linear addresses. The confirmed sequence is:

| Offset | Operation | Result/control |
|---:|---|---|
| 22F7h | Compare dword at 04000000h with AAAA5555h | Mismatch branches to 2381h |
| 2308h | Write 5555AAAAh at 04000000h | Establishes test pattern |
| 2315h | Write FFFFFFFFh at 04000100h | Adjacent-address disturbance/write |
| 2322h | Compare 04000000h with 5555AAAAh | Mismatch branches to 2381h |
| 2333h | Set BH=00h | Result selector before the 04800000h comparison |
| 2335h | Compare 04800000h with 5555AAAAh | Equality branches to 2381h |
| 2346h | Set BH=02h | Selector for the next comparison |
| 2348h | Compare 04000800h with 5555AAAAh | Equality branches to 2381h |
| 2359h | Set BH=01h | Selector for the next comparison |
| 235Bh | Compare 04001000h with 5555AAAAh | Equality branches to 2381h |
| 236Ch | Set BH=03h | Selector for the next comparison |
| 236Eh | Compare 04002000h with 5555AAAAh | Equality branches to 2381h |
| 237Fh | Set BH=04h | Final selector before falling through to 2381h |

The 235Bh–2380h span is 38 bytes and consists of the final two prefixed 32-bit compare/conditional-branch pairs plus the BH=04h fallback assignment. It is a fall-through continuation of the earlier protected-mode memory test, not an independently called routine. The generator now seeds 235Bh with a 26h-byte bound ending exactly at 2380h; 2381h remains the separate continuation already documented in the 23CEh–29F5h ledger.

The comparison addresses are 04000000h, 04000100h, 04800000h, 04000800h, 04001000h and 04002000h. The immediate constants and branches are confirmed from the bytes. This report does not infer the physical RAM size or the exact alias topology from these comparisons alone; those depend on the ALi memory mapping established by the preceding setup code.

The follow-on at 2381h packs DX nibbles into AH and writes ALi index 10h through 8DDCh; 2396h packs BX nibbles and writes index 11h; 23ACh writes index 16h. The complete crafted-return sequence and the transition back to real mode are documented in [AMI486_ADDRESS_LEDGER_REGION_23CE_29F6_20261117.md](AMI486_ADDRESS_LEDGER_REGION_23CE_29F6_20261117.md).


## 11. Earlier DH-selected alias-test tail at 21E1h–222Ch

A second selector pass precedes the BH-selected sequence documented above. It is part of the same protected-mode extended-memory probe and is reached by fall-through; there is no independent CALL/JMP entry at 2207h.

| Offset | Operation | Result/control |
|---:|---|---|
| 21E1h | Compare dword at 04800000h with 5555AAAAh | Equality branches to 222Dh |
| 21F2h | Set DH=02h | Selector before next compare |
| 21F4h | Compare 04000800h with 5555AAAAh | Equality branches to 222Dh |
| 2205h | Set DH=01h | Selector before next compare |
| 2207h | Compare 04001000h with 5555AAAAh | Equality branches to 222Dh |
| 2218h | Set DH=03h | Selector before next compare |
| 221Ah | Compare 04002000h with 5555AAAAh | Equality branches to 222Dh |
| 222Bh | Set DH=04h | Final selector before falling through to 222Dh |

The 2207h–222Ch span is 26h bytes. The compare operations use the flat ES=0008h selector and 32-bit absolute addresses. The result selector is carried in DH; the later BH-selected pass at 2333h–2380h is a separate sequence and must not be merged with this one.

At 222Dh the code loads AX=1616h and jumps to the ALi indexed-register read helper at 8DC Fh (the target is 8DCFh). Its stack-threaded return continues at 2238h, where the returned AL value is ORed with 30h, exchanged into AH, and written back through 8DDCh using another crafted stack return. The exact hardware meaning of ALi register 16h is not assigned here; the observed read/modify/write is the supported conclusion.

The candidate generator now seeds 2207h with a 26h-byte bound ending at 222Ch, alongside the 235Bh continuation seed.
