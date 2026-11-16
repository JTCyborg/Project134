# AMI486 semantic map — phase 37 (2026-11-16)

## Scope and method

This phase resolves the timer-based measurement routine called by 8F12h. It covers 8F50h, 9033h, 9087h and 9096h. The evidence is instruction-level flow in the 64 KiB linear 16-bit listing, including the generated test bytes at segment 1000h.

## 1. Test-code construction at 8F50h

8F50h saves DS and ES, disables interrupts, and sets ES=1000h. It creates two test stubs:

- At 1000:0000, it writes 03E8h words of F7F3h, followed by byte CBh.
- At 1000:0800, it writes 03E8h words of F6F3h, followed by byte CBh.

Each region therefore contains 1000h? No: the REP STOSW count is 03E8h words, i.e. 1000 decimal words / 2000 bytes, followed by CBh. The first region occupies offsets 0000h–07D0h inclusive of its terminator, and the second 0800h–0FD0h. The gap is intentional.

The opcode pairs are repeated 16-bit DIV instructions:
- F7 F3 decodes as DIV BX (word divide).
- F6 F3 decodes as DIV BL (byte divide).

CBh is RETF, so each far-called stub returns to the measuring routine. The routine sets BX=FFFFh before each call.

## 2. Timer 2 initialization

9096h configures the PC-compatible PIT channel 2:

1. Reads port 61h, clears bits 0–1, writes the result back.
2. Writes B4h to PIT command port 43h.
3. Writes 00h twice to channel-2 data port 42h.

B4h selects channel 2, low-byte/high-byte access, mode 2 (rate generator), binary count. A zero reload value represents 65536. The port-61h writes disable the channel-2 gate and speaker-data enable before programming.

## 3. Timed execution in 9033h

9033h performs two independent timing samples:

### Sample A — word DIV stub

- Initializes channel 2 through 9096h.
- Reads and saves port 61h.
- Sets bit 0 of port 61h to start the channel-2 counter.
- Far-calls 1000:0000.
- Restores port 61h with bits 0–1 cleared.
- Reads the channel-2 counter through 9087h and stores the resulting elapsed-count value at 1000:F800.

### Sample B — byte DIV stub

- Repeats the same gate/start sequence.
- Far-calls 1000:0800.
- Stops the counter.
- Reads the counter through 9087h.
- Subtracts the second sample from the first and returns the difference in AX.

9087h reads channel-2 counter low/high bytes from port 42h, assembles them into AX and NEGates AX. With a 65536 reload, this yields the elapsed down-count modulo 65536, assuming the measured interval is shorter than one full wrap.

The returned quantity is therefore a difference between two timer-2 measurements: the time spent executing 1000 word-DIV instructions minus the time spent executing 1000 byte-DIV instructions. It is not a direct PIT frequency reading and is not itself a CPU clock value in MHz.

## 4. Category mapping and POST visibility

8F12h consumes the difference returned by 8F50h. It maps the result into BDA byte 0040:E2h using thresholds 10h, 14h, 19h, 21h, 28h, 32h and 42h, inclusive, with larger values assigned category 7. It also emits the category to POST port 80h.

This makes 0040:E2h a BIOS performance/timing category derived from relative DIV instruction timing. It is not a direct identification string or an independently measured processor frequency.

## 5. Caveats

- The arithmetic result is a modular difference of two 16-bit timer samples. The BIOS assumes both timed runs complete without a full 65536-count wrap.
- The measurement is sensitive to CPU implementation, DIV latency, bus/memory execution effects, interrupt masking, and emulator timing fidelity.
- 8F50h disables interrupts during setup and measurement, reducing interrupt contamination.
- The use of BX=FFFFh avoids a zero divisor, but the exact initial DX:AX / AX state and DIV exception behavior should be validated against the full caller state before treating the score as a calibrated benchmark.
- The exact real-world category-to-CPU-speed mapping remains unproven; no MHz labels are assigned.

## Confirmed result

The BIOS measures the relative execution-time difference between repeated 16-bit DIV BX and 8-bit DIV BL instruction streams using PIT channel 2, stores the derived category in BDA 0040:E2h, and later uses that category to select ALi timing-table rows. This explains the path from CPU timing measurement to the chipset table selection without assigning unsupported hardware meanings to ALi registers.

## Reproducibility

Primary listing: `analysis/disasm/ami486_full_linear_16bit.disasm.txt`.
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
Key ranges: 8F50h–9032h, 9033h–9095h, 9096h–90B0h.
