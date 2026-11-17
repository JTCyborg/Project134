# AMI486 address-ledger region 23CEh–29F5h — POST shadow, ALi configuration and memory tests

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Source: `ami486.bin`, 65,536 bytes  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Decode: Capstone x86, 16-bit mode; bounded independent candidate windows plus explicit data/return-word ranges.

## 1. Coverage and method

The former candidate gap `23CEh–29F5h` (1,576 bytes) now has **zero uncovered bytes** in the code-window/data-range union:

| Classification | Bytes |
|---|---:|
| Candidate code-window bytes | 1,492 |
| Explicit data bytes | 85 |
| Code/data overlap | 1 |
| Union | **1,576 / 1,576 (100%)** |

The single overlap is byte `2686h`: it is both the first byte of the GDT's inclusive limit and the first byte of an executable stream. This is a real structural overlap, not a reason to count the byte twice.

This is address-ledger coverage, not proof that every instruction is reachable at runtime or that every hardware register bit has a known name. The `299Ah` routine remains a candidate indirect entry with no direct caller found.

## 2. Stack-threaded alias-test return chain at 2381h–2409h

The continuation immediately before this region is now aligned as follows:

| Code entry | Stack word written | Helper jumped to | RET resumes at |
|---:|---:|---:|---:|
| 2381h | 2394h–2395h = 2396h | 8DDCh | 2396h |
| 2396h | 23AAh–23ABh = 23ACh | 8DDCh | 23ACh |
| 23ACh | 23B6h–23B7h = 23B8h | 8DDCh | 23B8h |
| 23B8h | 23CEh–23CFh = 23D0h | F66Eh | 23D0h |
| 23D0h | 23DAh–23DBh = 23DCh | 552Dh | 23DCh |

Consequently, `23AAh`, `23B6h`, `23CEh` and `23DAh` are return-address words, **not instruction entries**. The actual continuations are `23ACh`, `23B8h`, `23D0h` and `23DCh`.

- `2381h` masks DX with `0F0Fh`, packs DH/DL into AH, selects ALi index `10h`, and writes it through `8DDCh`.
- `2396h` masks BX with `0F0Fh`, packs BH/BL into AH, selects ALi index `11h`, and writes it through `8DDCh`.
- `23ACh` selects ALi index `16h` with AH=0 and writes it through `8DDCh`.
- `23B8h` loads ES=`0010h`, clears CR0.PE, and jumps to `F66Eh` to disable A20. Its crafted return word at `23CEh` sends execution to `23D0h`.
- `23D0h` sets BX=`0400h` and calls the shared test at `552Dh) through a crafted stack return.

### 552Dh shared pattern-test helper

The helper uses BX as a **word count**, not a fixed 64-KiB length. It writes and verifies four patterns in order: `8080h`, `5555h`, `3333h`, and `0000h`, using `REP STOSW` / `REPE SCASW`.

- Caller `23D0h` passes BX=`0400h`: 1,024 words = **2 KiB** at ES:0000.
- Another caller at `5FBEh` sets BH=`08h` while preserving BL; its word count depends on BL inherited from its caller. It is not valid to describe the helper as always testing 64 KiB.
- The return flags report the last comparison; `23DCh` branches to the success continuation at `23E4h` only when ZF=1. Otherwise it sets BP=3 and enters the fatal path at `F4A5h`.

## 3. ROM-shadow copy family: 240Ah–2494h

The common routine begins at `2457h`. Each front-end sets BX (segment), CX (word count) and DL (ALi register-13h mask), then jumps to the common body.

| Entry | BX segment | CX words | Byte span | DL mask |
|---:|---:|---:|---:|---:|
| 240Ah | F000h | 8000h | 64 KiB | C0h |
| 2415h | C000h | 4000h | 32 KiB | 01h |
| 2420h | C800h | 4000h | 32 KiB | 02h |
| 242Bh | D000h | 4000h | 32 KiB | 04h |
| 2436h | D800h | 4000h | 32 KiB | 08h |
| 2441h | E000h | 4000h | 32 KiB | 10h |
| 244Ch | C800h | 4000h | 32 KiB | 20h |

The common body:
1. Saves ES and DS.
2. Reads ALi register `13h`, ORs in DL, and writes it back.
3. Reads ALi register `14h`, clears bits 0–1, sets bit 1, and writes it back.
4. Sets DS=ES=BX, SI=DI=0, and executes `REP MOVSW` for CX words. The source and destination segment are the same; the chipset's shadow control changes the underlying read/write mapping.
5. Reads ALi register `14h` again, clears bit 1, sets bit 0, and writes it back.
6. Restores DS/ES and returns.

This is consistent with enabling shadow writes, copying the currently visible ROM window into its shadow RAM, then switching the window to the protected/read mode. The exact physical mapping and meaning of the ALi register bits remain chipset-specific and are not inferred here.

The 23E4h POST continuation calls `240Ah` (the 64-KiB F000h window) before `2495h`. The other C000h–E000h helpers are separately option-gated by POST callers described in phase 21.

## 4. Feature-gated ALi register 12h/15h configuration: 2495h–2536h

`2495h` first clears bit 2 in ALi register `12h`. It then reads CMOS `42h`; if bit 2 is clear, it skips the weighted calculation and returns.

When enabled, the code reads ALi registers `10h` and `11h`, splits their high/low nibbles, and uses the five-byte table at `2088h–208Ch`:

```
2088: 01 04 02 10 40
```

The nibble-indexed weights are therefore `01h, 04h, 02h, 10h, 40h`. A nibble value of `0Fh` is treated as a no-contribution sentinel. The four selected contributions are accumulated and written to ALi register `15h`; bit 2 is then set in ALi register `12h`.

The code does not bounds-check arbitrary nibble values before indexing this five-byte table. The expected valid nibble domain is not established from this routine alone.

## 5. AUTO Config row selector and ALi field writers: 2537h–2628h

`25C4h` is a shared row-offset helper. It reads CMOS `B3h`, tests bit 2 and the CPU mode via SMSW, and in one path reads BDA byte `0040:E2h`. It returns an offset in AX, with the AUTO Config tables using a **20-byte row stride** (`IMUL 14h`).

The row data is read through four table bases and written to ALi indexed registers:

| Entry | Table base | ALi register written |
|---:|---:|---:|
| 2537h | 87B5h | 20h |
| 256Ah | 87ADh | 17h |
| 2588h | 87A9h | 16h |
| 25A6h | 87B1h | 19h |

Each handler selects a row using the offset returned by `25C4h`, reads the table word, combines the value with the current indexed register value, and writes the result through `8DDCh`. Exact user-facing option names and hardware meanings of the destination fields remain unresolved.

## 6. Memory-read and protected-mode scan helpers: 2629h–26F8h

### 2629h — low-memory read sweep

Sets DS=0000h, SI=0, CX=8000h, and executes `REP LODSW`. BX advances by 1000h segment units until it reaches 8000h. This reads eight 64-KiB segment windows, covering the first 512 KiB in 64-KiB steps. It restores DS and returns through DI.

### GDT at 2646h–2686h and protected-mode read at 2686h

The six-byte GDTR operand begins at `264Eh`:

- Limit = `0040h`
- Base = `000F2646h` (linear address F2646h)

The GDT begins at F2646h. Its eight complete descriptors are:

| Selector | Descriptor address | Base | Limit | Access/flags | Use confirmed here |
|---:|---:|---:|---:|---|---|
| 0000h | 2646h | 00000000h | 0 | 00/00 | Null |
| 0008h | 264Eh | 000F2646h | 0040h | 00/00 | GDTR operand overlays this slot; not loaded as a segment |
| 0010h | 2656h | 00000000h | FFFFh | 93/00 | Loaded into ES before leaving protected mode |
| 0018h | 265Eh | 03838000h | FFFFh | 93/00 | Not selected in this local path |
| 0020h | 2666h | 03A30000h | FFFFh | 93/00 | Not selected in this local path |
| 0028h | 266Eh | 03820000h | FFFFh | 93/00 | Not selected in this local path |
| 0030h | 2676h | 03840000h | FFFFh | 93/00 | Not selected in this local path |
| 0038h | 267Eh | 00000000h | FFFFFFFFh | 93/8F | Flat 32-bit data segment loaded into ES |

The inclusive GDTR limit also reaches byte `2686h`, which is the first byte of the executable stream below. Thus `2686h` is a genuine code/GDT-limit overlap; the memory test uses selectors 0038h and 0010h, not the partial descriptor slot beginning at 2686h.

At `2686h`, the code sets ECX=`00040000h` dwords (1 MiB), ESI=`00100000h` (1 MiB), loads the GDT, sets CR0.PE, loads ES=0038h, and executes `REP LODSD` through ES:[ESI]. It reads 1 MiB beginning at physical 1 MiB. It then loads ES=0010h, clears CR0.PE, and jumps to DI.

### 26BEh and 26D6h — additional read sweeps

- `26BEh` sets DS=4000h, reads 8000h words (64 KiB), increments the segment by 0800h (32 KiB physical), and repeats until the segment reaches 9800h. It therefore performs overlapping 64-KiB reads at 32-KiB strides across the upper conventional-memory window, then jumps to DI.
- `26D6h` saves DS/SI and reads 8000h words from DS=0700h, then DS=1700h (two 64-KiB reads), restores SI/DS and returns. No comparison or write is performed in this helper.

## 7. CMOS B518h-gated POST memory test: 26F9h–284Fh

`26F9h` disables interrupts, reads CS:`B518h`, and calls `8300h`. A zero result skips to `284Fh`; a nonzero result enters the test and saves DS/ES plus the prior SS:SP values from BDA `0040:0067/0069h`.

It configures ALi registers `19h` and `18h`, then uses `2686h` for the 1-MiB protected-mode read. At `2761h`, DS=1000h, CX=2, ESI=0 and EAX=55AA55AAh. The loop at `2772h` writes the pattern at offsets 0, 4 and 8 (with the +4 write overlapping the next iteration's base write), reads spaced offsets +800h/+1000h/+1800h/+2000h, and compares the two tested base dwords. The spaced reads are not compared in this loop.

On the successful path it sets DS=ES=1000h and calls `29BBh` through a crafted return to `27CCh`. The `29BBh` routine:
1. Reads 2000h dwords (32 KiB) from DS:0000.
2. Fills 2000h words (16 KiB) at ES:0000 with 55AAh and verifies them.
3. If that pattern passes, complements AX and repeats with AA55h.
4. On either mismatch, skips further pattern passes, clears the 16-KiB test window, and returns with ZF=0.
5. Only after both patterns pass does it clear the window and return with ZF=1.

This corrects the earlier interpretation that a mismatch itself retries the fill/scan. The retry is the intentional second pattern pass after the first pattern succeeds; a mismatch exits to the clear-and-return path.

At `27CCh`, ZF=1 continues the segment loop; otherwise the code sets BP bit 14 and jumps to `8D83h` with a crafted return at `27DAh`. The ALi/memory fallback reconfiguration helper returns to `27DCh`, which jumps to the cleanup path at `2800h`. This is a recovery/configuration path, not a fatal error logger.

On success, DS advances by 0400h (16 KiB physical) and the 16-KiB test window is repeated from segment 1000h through 8C00h. The final path reads CMOS B3h through EE94h, sets bit 0, writes it back through EE9Dh, updates ALi register 19h, performs a final protected-mode read at 2686h, updates ALi register 19h again, emits POST code 40h to port 80h, restores the saved SS:SP/DS/ES and returns.

All return words at 27CAh, 27DAh, 27F2h, 27FEh, 280Ah, 2816h, 2828h and 2834h are data, with the following continuation entries at 27CCh, 27DCh, 27F4h, 2800h, 280Ch, 2818h, 282Ah and 2836h respectively.

## 8. POST memory setup and timing classification: 2850h–29BAh

`2850h` sets ALi register C5h to 03h, programs register 19h and register 18h, and uses the protected-mode read helper at 2686h. It then calls `28F2h` to derive a memory timing class, maps the returned AL value to BL (70h→70h, 60h→30h, 50h→50h, 40h→10h, 30h→40h, 20h→00h), scans the 4000h–9800h memory window through `26BEh`, and updates ALi register 18h with the selected bits.

`28F2h` first reads 16-KiB blocks from segment 9C00h downward in 0400h segment steps until 1C00h, then begins the timed scan at segment 1800h. The timing helper at `296Bh` latches PIT channel 0 through port 43h, samples counter 40h, reads 2000h words (16 KiB) from DS:0000, samples the counter again, and returns the elapsed count in BX. The indirect continuation at `2911h` stores the first sample in DX and switches DI to `291Bh`. Each `291Bh` iteration computes the absolute difference from the prior sample; if the high byte is at least 1, it increments BP. DS then advances by 0400h and the scan continues through 9C00h.

The final continuation at `2937h` writes the count to port 81h, caps it at 40h, converts it to a small shifted class in AH/AL, stores AH at BDA `0040:E0h`, and returns. This is a **relative timing-difference classifier across adjacent 16-KiB reads**, not a direct RAM-capacity measurement or a single absolute speed measurement.

The separate `299Ah` candidate routine saves DS/SI and reads eight 64-KiB segments from 1000h through 8000h. No direct near CALL/JMP reference to 299Ah was found in the linear listing. Its entry provenance remains unresolved; do not merge it into the 28F2h timing loop without a runtime DI source.

## 9. CMOS B6h.0 selector at 29EDh

`29EDh` loads AX=B6B6h, calls the CMOS read helper EE94h, tests bit 0, and returns with ZF reflecting CMOS B6h.0. The POST continuation at 23F2h uses that ZF to decide whether to call 8F12h and the AUTO Config writer 2537h.

## 10. Remaining uncertainties

- Physical memory aliases depend on the ALi register values and chipset mapping; this report describes segment-relative operations and programmed selectors only.
- The exact meanings of ALi registers 10h–20h and the AUTO Config fields remain unnamed.
- The 26D6h two-segment read helper has no direct caller established in this pass.
- The `299Ah` secondary memory sweep has no direct caller or DI source established.
- The 2629h low-memory sweep's upstream DI continuation remains caller-dependent.
- The partial GDT slot beginning at 2686h is inside the inclusive GDTR limit but is not used by the selectors loaded in this path.

## 11. Candidate-mask update

After adding bounded seeds and explicit return-word/GDT data ranges, the generated candidate map contains 731 code windows and 212 data ranges. Across the whole ROM:

- 35,674 unique code-window bytes
- 16,510 unique data-range bytes
- 214 code/data overlap bytes
- 51,970-byte union = **79.30%**
- 13,566 bytes remain outside the candidate union
- 69 uncovered intervals remain

These figures are a candidate inspection mask only. They do not mean that 79.30% of the BIOS has been semantically decoded.
