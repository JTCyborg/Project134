# AMI486 address ledger — region 2436h–29F5h

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Candidate generator: `tools/disasm_ami486_candidate_windows.py`  
Generator blob: `dcee77b0c9b7967c4a91b3108b60daca920933c3`  
Candidate manifest blob: `c7bd8b7e677a78ed360c8f5489236d6b5184ce25`  
Candidate listing blob: `ae844f3ffd73788dea8b7944668df933bb836336`

## 1. Region result

The 1,472-byte interval `2436h–29F5h` now has **zero uncovered bytes in the candidate code/data union**. The last two holes were:
- `247Ch–2494h`: tail of the common ALi memory-window worker beginning at `2457h`;
- `29EBh–29ECh`: the two-byte `FF E7 / JMP DI` trampoline adjacent to the `29BBh` RAM test and `29EDh` CMOS helper.

The second item is byte-confirmed as an instruction, but its caller/entry provenance is not established. It remains an alternate-entry candidate, not a proven reachable function.

This region includes previously analyzed phase-35/36 AUTO Config consumers and phase-72/73 memory-test paths. This report consolidates them with the remaining code/data and stack-return classifications; it does not replace their historical phase reports.

## 2. ALi memory-window selection and touch worker — 240Ah–2494h

The common worker begins at `2457h`; the region of interest begins partway through its selector family.

### 2.1 Selector entries

| Entry | BX segment | CX words | DL mask | Known incoming references |
|---|---:|---:|---:|---|
| `240Ah` | F000h | 8000h | C0h | `23ECh` |
| `2415h` | C000h | 4000h | 01h | `1BF6h` |
| `2420h` | C800h | 4000h | 02h | `1B71h`, `1EA8h` |
| `242Bh` | D000h | 4000h | 04h | `1B7Fh`, `1EB6h` |
| `2436h` | D800h | 4000h | 08h | `1B8Dh`, `1EC4h` |
| `2441h` | E000h | 4000h | 10h | `2053h` |
| `244Ch` | C800h | 4000h | 20h | `2061h` |

Each selector loads BX/CX/DL and jumps to the common worker at `2457h`.

### 2.2 Common worker at 2457h

The byte-aligned sequence is:

1. Save ES and DS.
2. Read ALi indexed register 13h through `8DCFh`, OR in DL, and write it through `8DDCh`.
3. Read register 14h, clear bits 0/1 with `AND AL, FCh`, set bit 1, and write it.
4. Set DS=ES=BX, clear SI/DI, and execute `REP MOVSW` for CX words.
5. Read register 14h again, clear bit 1 and set bit 0, write it, restore DS/ES and return.

Because DS and ES are set to the same segment and SI/DI both start at zero, the MOVSW is a same-segment self-copy. It forces reads/writes across the selected memory window; it is not a copy from a distinct source buffer. The literal ALi register masks and segment windows are established; the board-level meaning of the register-13/14 bits is not.

## 3. CMOS 42h-gated ALi register conversion — 2495h–2536h

Entry `2495h` is called from `23EFh`.

- It first reads ALi register 12h, clears bit 2 and writes it back.
- It reads CMOS register 42h through `EE94h`. If bit 2 is clear, it returns at `2536h`.
- If enabled, it reads ALi registers 10h and 11h.
- Each high/low nibble is converted through the 16-byte lookup table at `2088h`; sentinel nibble Fh/F0h contributes zero.
- The converted values are summed and written to ALi register 15h.
- It then rereads register 12h, sets bit 2 and writes it back.

This proves a CMOS-gated conversion of the two ALi register bytes into register 15h. Its higher-level purpose is not assigned here.

## 4. AUTO Config ALi register consumers — 2537h–2628h

These four callbacks use the shared row-offset helper at `25C4h` and the 14-row table view based at `87A9h` (20-byte row stride; see phase 36 and region report `873Ch–8DCEh`).

| Callback | Table field base | ALi register | Merge mask |
|---|---:|---:|---:|
| `2537h` | `87B5h` | 20h | F8h |
| `256Ah` | `87ADh` | 17h | 7Ch |
| `2588h` | `87A9h` | 16h | F0h |
| `25A6h` | `87B1h` | 19h | 9Fh |

Each callback:
1. Calls `25C4h` to obtain the selected row offset.
2. Adds that offset to its field base.
3. Loads the selected word from CS.
4. Combines the selected field bits with the current ALi register value using the callback-specific mask.
5. Writes the updated indexed register through `8DDCh`.

The `2537h` path has a separate register-20 bit-3 branch which changes how the selected word is reduced to the final three-bit field.

### 4.1 Row selector at 25C4h

- Reads CMOS B3h.
- If B3h bit 2 is set, or the SMSW/AH state forces the alternate path, it uses the BDA byte `0040:E2` plus six as the row number.
- Otherwise it uses `BDA:0040:E2 & 7`.
- For category 5 with CMOS B3h bit 1 set, it selects row 7.
- It multiplies the row number by 20h and returns the byte offset.

The resulting 0–13 row range explains the 14-row lookup view at `87A9h`.

## 5. Memory-touch helpers and protected-mode GDT — 2629h–26F8h

### 5.1 2629h — 512-KiB segment read

Saves DS, then reads eight 64-KiB segments:
`0000h, 1000h, 2000h, 3000h, 4000h, 5000h, 6000h, 7000h`.

Each segment is read with `CX=8000h` and `REP LODSW`. DS is restored and control returns through DI. Incoming reference: `8D6Fh`.

### 5.2 GDT object at 2646h–2686h

The six-byte GDTR pseudo-descriptor at `264Eh` is:

- limit = `0040h`;
- base = `000F2646h` (physical ROM address F2646h).

The table includes the null descriptor at `2646h), a pointer-shaped entry at `264Eh` (the GDTR itself), and the data descriptors used by selectors:
- selector `0010h`: base-zero 64-KiB data segment;
- selector `0038h`: base-zero flat 4-GiB data segment.

The inclusive GDTR limit reaches byte `2686h`, which is also the first byte of the executable helper at `2686h`. The selected descriptors end at `2685h`; the one-byte limit/code overlap is retained explicitly rather than silently classifying the byte as exclusively data or code.

### 5.3 2686h — protected-mode 1-MiB read

- Loads ECX=`40000h` dwords and ESI=`00100000h`.
- Executes `LGDT CS:[264Eh]`.
- Sets CR0.PE, loads ES=`0038h` (flat data descriptor), clears direction and performs `REP LODSD` over 1 MiB beginning at linear address 1 MiB.
- Loads ES=`0010h`, clears CR0.PE and jumps through DI.

Incoming references include `8D69h` and `8DA2h`; internal callers in the POST paths also use it.

### 5.4 26BEh and 26D6h — additional segment sweeps

- `26BEh`: starts DS=4000h and reads 64 KiB per segment, increasing the segment by 0800h until A000h. This touches 12 segments (768 KiB), then jumps through DI. Called from `28DCh).
- `26D6h`: reads two 64-KiB segments beginning at 0700h and 1700h, restores SI/DS and returns. No direct near caller was found in the current listing; retain it as a candidate helper with unresolved reachability.

## 6. CMOS-gated POST memory test — 26F9h–284Fh

Entry `26F9h` is called from `1ED6h`. It tests `CS:B518h` through `8300h`; the result selects the short return at `284Fh` or the extended memory-test path.

The extended path:
1. Saves DS/ES and the BDA memory-pointer words at `0040:0067` and `0040:0069`, then sets SS=CS.
2. Uses `8CB2h` to clear CR0 cache-disable bits when its PE/AH preconditions permit.
3. Sets bits 0/1 in ALi register 19h and bit 1 in register 18h through the DI-returning indexed helpers.
4. Calls the protected-mode 1-MiB read helper at `2686h`.
5. Clears bits 0/1 in ALi register 19h.
6. Runs a memory-alias probe at DS=1000h with EAX=`55AA55AAh`, checking offsets 0, 4, 800h, 1000h, 1800h and 2000h over two iterations.
7. On the success path, uses `SP=27CAh; JMP 29BBh` to invoke the two-pattern RAM test. The crafted stack word at `27CAh` makes RET at `29EAh` resume at `27CCh`; ZF selects the success continuation at `27DEh`.
8. The success path advances DS by `0400h` (16 KiB) and repeats the `29BBh` test until segment 9000h, covering 32 adjacent 16-KiB windows (512 KiB).
9. It then sets CMOS B3h bit 0 and ALi register 19h bit 3 before returning.

On the failure path, BP bit 14 is set and a crafted stack return invokes `8D83h`; the continuation at `27DCh` jumps to `2800h`.

### 6.1 Stack-return words in the 27xx/28xx path

| Stack slot | Value popped as IP | Consumer |
|---|---:|---|
| `27CAh–27CBh` | `27CCh` | RET from `29EAh` |
| `27DAh–27DBh` | `27DCh` | DI-return path in `8D83h` |
| `27F2h–27F3h` | `27F4h` | CMOS B3h read through `EE94h` |
| `27FEh–27FFh` | `2800h` | CMOS B3h write through `EE9Dh` |
| `280Ah–280Bh` | `280Ch` | ALi indexed read through `8DCFh` |
| `2816h–2817h` | `2818h` | ALi indexed write through `8DDCh` |
| `2828h–2829h` | `282Ah` | ALi indexed read through `8DCFh` |
| `2834h–2835h` | `2836h` | ALi indexed write through `8DDCh` |

These words are data, not instructions. The continuation streams are independently seeded in the candidate listing.

### 6.2 Failure/restore continuation at 2800h–284Fh

The continuation at `2800h` reads ALi register 19h, sets bits 0/1 and writes it; calls the protected-mode 1-MiB reader at `2686h`; rereads register 19h, clears bits 0/1 and writes it; then loads DS=0040h, writes port 80h, restores SS:SP from the BDA-saved words and restores DS/ES before RET at `284Fh`.

## 7. POST memory/timing configuration — 2850h–29EAh

### 7.1 2850h helper

Entry from `1ECBh`. It:
- writes ALi register C5h=03h;
- uses `8CB2h` cache-state helper;
- sets ALi register 19h bits 0/1;
- writes ALi register 18h=`43h`;
- calls the protected-mode 1-MiB read helper at `2686h`;
- clears ALi register 19h bits 0/1;
- calls the PIT/memory sampler at `28F2h`;
- maps the returned timing value to BL values `70h/30h/50h/10h/40h/00h` for measured values `70h/60h/50h/40h/30h/20h`; other values take the `8D83h` helper path;
- invokes the 768-KiB segment sweep at `26BEh`;
- reads ALi register 18h, applies `AL &= 8Dh; AL |= BL`, writes it and returns.

### 7.2 28F2h — PIT-based memory scan

Entry by CALL from `2893h`. It reads 16 KiB at a time from segment 9C00h down to 1C00h, stepping by 0400h paragraphs (16 KiB). This is 32 windows / 512 KiB. It then selects the timing-sample continuation through DI.

The continuations at `2911h`, `291Bh` and `2937h`:
- retain the first PIT sample in DX;
- compare later samples and accumulate a count in BP;
- write the count to port 81h;
- clamp the value to 40h;
- encode the leading-bit/count result and store it at BDA `0040:E0`.

### 7.3 296Bh — PIT counter sample

The helper latches PIT channel 0 through port 43h, reads the counter through port 40h, performs a 16-KiB `REP LODSW` memory read, latches/reads the counter again and returns the elapsed delta in BX through DI.

### 7.4 299Ah — candidate secondary sweep

This helper reads eight 64-KiB segments beginning at DS=1000h and increasing by 1000h (512 KiB total), restores SI/DS and returns. No direct near caller was found; the current candidate seed is retained because an indirect DI continuation may select it, but reachability is unproven.

## 8. Second-stage RAM test and CMOS selector — 29BBh–29F5h

### 8.1 29BBh — two-pattern memory test

The caller at `27C7h` sets DS=ES=1000h, loads SP=27CAh and jumps to `29BBh`.

The routine:
1. Reads 2000h dwords (32 KiB) with `REP LODSD`.
2. Writes 2000h words (16 KiB) of `55AAh` with `REP STOSW`.
3. Verifies the 16-KiB block with `REPE SCASW`.
4. Inverts AX to `AA55h` and repeats the write/verify pass.
5. Clears 16 KiB to zero and returns.

The crafted return word at 27CAh makes the RET at 29EAh resume at 27CCh. Phase 73 supersedes the incorrect phase-72 return-target interpretation; retain phase 73 as authoritative.

### 8.2 29EBh — unproven JMP DI stub

Bytes `FF E7` decode as `JMP DI`. It is adjacent to the RAM-test RET and CMOS helper. No direct near caller was found; it is kept as a candidate executable entry, not a proven reachable routine.

### 8.3 29EDh — CMOS B6h.0 selector

Loads AX=B6B6h, calls `EE94h` to read CMOS B6h, tests bit 0 and returns flags. This is the helper described in phase 73; it does not write CMOS.

## 9. Incoming references and confidence

Direct near references from the full linear listing into this region include:
- `1BF6h -> 2415h`; `1B71h/1EA8h -> 2420h`; `1B7Fh/1EB6h -> 242Bh`;
- `1B8Dh/1EC4h -> 2436h`; `2053h -> 2441h`; `2061h -> 244Ch`;
- `23EFh -> 2495h`;
- `1C7Ch/23FAh -> 2537h`; `1C7Fh -> 256Ah`; `1F57h -> 2588h`; `1F5Ah -> 25A6h`; `1C47h -> 25C4h`;
- `8D6Fh -> 2629h`; `8D69h/8DA2h -> 2686h`;
- `1ED6h -> 26F9h`; `1ECBh -> 2850h`; `2893h CALL 28F2h`; `28DCh -> 26BEh`;
- `27C7h -> 29BBh`;
- `1A1Dh/1C72h/1F4Dh/23F2h -> 29EDh`.

The selector entries at 240Ah–244Ch are also referenced from the listed POST/setup paths. `26D6h`, `299Ah` and `29EBh` remain candidate entries without a proven direct near caller. As with other ledger regions, source-side instruction boundaries for every incoming reference have not all been independently re-audited.

## 10. Remaining uncertainties

- The board-level meanings of ALi registers 12h–15h, 18h–20h and the specific masks used by the memory-window worker are not established.
- The exact role of the 2088h nibble lookup table in the 2495h conversion is byte-traced, but its external timing/DRAM interpretation is not.
- The GDT's selector-0010h/0038h descriptors are used; other descriptor slots and the one-byte limit overlap at 2686h are not needed by the observed selector sequence.
- The direct entry into 26D6h and 299Ah is unresolved.
- The two-byte 29EBh JMP DI stub has no proven caller.
- The physical RAM size represented by the read/touch loops is not inferred solely from the number of bytes read; these are memory-touch/probe sequences, not a confirmed DIMM-size report.

## 11. Candidate-mask status

Latest candidate mask:
- 731 code windows;
- 208 data ranges;
- 35,692 unique code-window bytes;
- 16,504 unique data-range bytes;
- 226 overlap bytes;
- 51,970-byte union (**79.30%** of the 64-KiB image);
- 69 uncovered intervals;
- 227 pages touched, 153 fully covered.

The selected interval `2436h–29F5h` has zero uncovered bytes in this mask. This is an address-inspection mask, not a whole-ROM semantic completion percentage.

The next largest uncovered interval is `FA53h–FFFFh` (1,453 bytes), followed by `5A4Ch–5FE3h` (1,432 bytes) and `1365h–188Dh` (1,321 bytes).
