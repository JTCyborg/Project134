# AMI486 chipset Setup selectors and timing calibration — 2026-11-16

Source: ami486.bin, 65,536 bytes. Relevant generated windows: 2A04h, 2AC2h, 2B13h, 2B4Ch, 2B91h, 2BD3h, 2C1Dh, 2C69h, 2CCFh, 2D11h, 2DF5h and 2E58h. Data tables and labels are emitted separately in ami486_candidate_windows_20261116.txt.

## 1. Setup option-selector cluster

The code at 2AC2h–2D10h consists of far-returning selector helpers. They read current option bytes in the BIOS data area at DS=0040h offsets E042h/E046h/E047h/E049h/E050h/E052h and return a CS-relative string pointer in AX. When BDA flag [E036h].0 is set, the helper selects the current label without changing the stored option. Otherwise, AL is used as a direction/step input, the option bits are updated with wrap/range checks, and the matching label pointer is returned.

### Selector tables

| Table | Entries | Values / labels |
|---:|---:|---|
| 2AB3h | 8 words | B62Dh = “7.19MHz”; B65Ch = “CLK2 /4”; B664h = “CLK2 /5”; B66Ch = “CLK2 /6”; B674h = “CLK2 /8”; B67Ch = “CLK2 /10”; B685h = “CLK2 /12”; final entry 5756h is an overlapping code target, not a confirmed string |
| 2B0Bh | 4 words | B5FFh “Slow”; B604h “Normal”; B60Bh “Fast”; B610h “Fastest” |
| 2B8Dh | 2 words | B6D3h “0 WS”; B6D8h “1 WS” |
| 2C15h | 4 words | B55Fh “Reserved”; B60Bh “Fast”; B604h “Normal”; B5FFh “Slow” |
| 2CAFh | 16 words | B6FBh through B761h: “0 us”, “0.25 us”, “0.5 us”, “0.75 us”, “1 us”, “1.25 us”, “1.5 us”, “1.75 us”, “2 us”, “2.25 us”, “2.5 us”, “2.75 us”, “3 us”, “3.25 us”, “3.5 us”, “3.75 us” |

The selector at 2AC2h uses [E050h] bits 0–2. The 2B13h and 2B4Ch selectors use separate two-bit fields in [E046h] (bits 0–1 and bits 2–3). The 2B91h and 2BD3h selectors independently use bits 6 and 5 of [E049h]. The 2C1Dh selector uses the low two bits of [E047h]. The 2C69h selector toggles [E042h].5 and returns “Enabled” (B571h) or “Disabled” (B568h). The 2CCFh selector uses the high nibble of [E052h] to select one of the 16 timing labels.

### Text data block

The contiguous label block B55Fh–B7B0h contains Setup strings including:
- state labels: Reserved, Disabled, Enabled, Absent, Present, Low, High, Off, On, No, Yes, Setup, Always;
- performance labels: Slow, Normal, Fast, Fastest;
- clock labels: 7.19MHz, 14.32MHz, 28.64MHz, CLK2 divisors, ATCLK/ATCLK2 divisors, OSC and CLKIO;
- cache labels: 64KB and 128KB;
- wait-state labels: 0–3 WS and 0–3 ns;
- timing labels: 0–3.75 us.

This establishes that the 2Axx–2Dxx helpers are part of a chipset/clock/cache/wait-state Setup option system, not random code or a standalone hardware test.

## 2. Hardware-state synchronization at 2A04h

The routine at 2A04h reads three CS-relative mask/descriptor words from the table at 87A9h, reads indexed chipset register 02h through the shared 8DCFh port-22h/23h helper, and merges selected bits into BDA option bytes E046h/E047h/E049h/E050h. It uses BDA flag E066h to choose a direct-display or update path. The exact field-to-register bit mapping in the 87A9h descriptor table remains to be documented.

## 3. Timing calibration at 2D11h

The routine builds two executable test blocks in segment 1000h:
- at 1000:0000h, 1000 copies of word F3F7h followed by RETF at offset 07D0h;
- at 1000:0800h, another 1000 copies followed by RETF at offset 0FD0h.

In 16-bit mode bytes F7 F3 decode as DIV BX. The measurement helper sets BX=FFFFh and far-calls each block, so each block executes 1000 DIV BX instructions before returning. The routine collects 40 timing samples into segment 1000h at offset F000h, computes their average, stores the average at DS:F800h, and computes 236Eh / average. Threshold comparisons then choose BX from the set 4, 5, 6, 8, 0Ah, 0Ch, 10h, 14h, 19h, 21h, 28h, 32h, 42h or 50h. It clears the 64 KiB scratch block and returns BX.

This is a CPU/memory timing calibration benchmark. Given the adjacent 0–3.75 us Setup labels, it likely supplies or calibrates a memory timing option, but the exact conversion from returned BX to [E052h] is not yet proven.

## 4. PIT channel-2 timing helper

- 2E58h clears port 61h bits 0–1, programs PIT channel 2 with control word B4h at port 43h (channel 2, LSB/MSB, mode 2, binary), and writes zero twice to port 42h.
- 2DF5h saves port 61h, starts the gate, far-calls the 1000h test block, stops the gate, then reads the down-counter through 2E49h. It repeats at 1000:0800h and returns the difference between the two measurements.
- 2E49h reads the two counter bytes from port 42h, combines them and negates the value to produce elapsed ticks.

## 5. Unresolved points

1. The final entry in table 2AB3h is 5756h, which enters an alternate instruction stream inside a routine beginning at 5753h. Its meaning and caller behavior remain unresolved.
2. The exact mapping from the 2D11h returned BX values to [E052h] and the 0–3.75 us labels is not yet proven.
3. The three descriptor words at CS:87A9h and their mapping to indexed chipset register 02h remain open.
4. The exact chipset vendor and register semantics must not be inferred from ports 22h/23h alone.

This report classifies the Setup label tables and timing benchmark. It does not claim the entire chipset Setup screen or chipset register map is complete.


## 6. Mixed final entry in the 2AB3h table

The eighth word at 2AC1h is 5756h. This is not a string start. The aligned stream at 5753h is:

```asm
5753 TEST WORD [E19D],0001h
5759 JZ 575Dh
575B MOV AL,CDh
575D RET
575E MOV AL,B3h
5760 TEST WORD [E19D],0002h
5766 JZ 576Ah
5768 MOV AL,BAh
576A RET
```

The table-selected entry 5756h begins inside the TEST instruction's immediate/displacement bytes and produces a different overlapping instruction stream. It is not safe to call this entry a string pointer or to infer its purpose from the neighboring clock labels. The exact caller behavior for selector value 7 remains open.


## Audit qualification — 2D11h entry and stack contract (2026-11-17)

The byte-aligned decode at 2D11h is now included as an independent candidate window, but this is **not proof of a normal function entry**. A raw scan of the 64 KiB ROM found no instruction-aligned near CALL/JMP target to 2D11h or 2D15h and no literal little-endian 2D11h/2D15h pointer. The stream ends with POP ES; POP DS; RET at 2DF2h–2DF4h, while the displayed stream itself contains no matching PUSH ES/PUSH DS prologue. Therefore the caller/entry mechanism and required stack frame are unresolved; a stack-threaded or alternate entry remains possible.

Confirmed internal call graph:
- 2D3Ch and 2D47h call 2DF5h.
- 2DF5h calls 2E58h to configure PIT channel 2 and calls 2E49h to read the counter.
- 2E18h and 2E3Eh call 2E49h.
- 2DFBh and 2E23h call 2E58h.
- The 2D47h sample loop executes 40 measurements; the earlier 2D3Ch call is a separate initial/warm-up invocation before the stored sample loop.

The benchmark writes 1000 copies of DIV BX (word F3F7h) plus RETF into each test block at 1000:0000h and 1000:0800h. The second block begins at 0800h and overlaps the first block's address range. The result is a timing-derived selector (BX values 04h through 50h); its exact conversion into Setup timing field [E052h] is still not proven. Do not label the return as a direct MHz measurement.
