# Project134 POST reconstruction — chipset I/O and PIT checks (D9A2h–DAA1h)

Date: 2026-11-18  
Branch: `main`  
Target reference: `ami486.bin`  
Source image SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

## Implemented

The NASM source `bios/src/reset.asm` now reconstructs the continuation following the stack-threaded return slot at D9A0h and the POST timer checks through DA9Fh.

### D9A2h–D9D9h — chipset/video-port initialization

The continuation:
- emits POST marker 12h to port 80h;
- writes zero to 03D8h;
- writes one to 03B8h;
- reads 03BAh and 03DAh;
- writes zero to 03C0h;
- restores ES and DS to segment zero;
- emits POST marker 13h and jumps to the existing CMOS-B3/PIT initialization entry at 1AFBh.

The port operations and instruction ordering follow the byte-aligned reference stream. No chipset register meaning beyond the observed I/O is inferred.

### D9DCh–DAA1h — PIT tests

The status-14h path:
- selects PIT channel 2 through control port 43h;
- writes 55h and AAh to channel-2 data port 42h;
- selects the channel-2 read-back/latch operation with 80h;
- reads the two bytes and compares the resulting AX with 55AAh;
- sets BP bit 0 only when the CS:8280h feature gate is enabled and the comparison fails.

The status-15h path programs channel 0 using control word 36h and two zero bytes at port 40h. When CS:8280h bit 7 is set and CS:8285h is zero, it invokes the existing F598h timing helper through the stack-return word at DA64h. The continuation at DA66h measures transitions on port 61h, compares the absolute count difference with 0Ah, and sets BP=1 / transfers to F4A5h on the enabled failure path. Success emits POST marker 1Bh and transfers to 5BF8h.

The conditional jump at DA66h is significant: zero CX skips the transition-measurement body and lands at the feature-gate test at DA8Dh. This is represented as a named branch target in the NASM source.

## Data and entry layout

- DA64h–DA65h is the inline stack-return word containing DA66h, not executable code.
- DAA2h–DFFFh is restored as zero-filled data/padding.
- E000h is restored as a far-jump entry stub to F000:E005.
- E005h is restored as a near-jump entry stub to F000:F73Bh.
- E00Eh–E057h contains the 74-byte IBM compatibility notice; E058h–E05Ah is zero padding.
- The reset gateway at E05Bh remains the existing implemented entry to D604h.

## Validation status

The source-level reconstruction is committed. A NASM/Visual Studio build and PCem runtime test have **not** been performed in this environment; do not treat this commit as a verified boot milestone. The original reference's D9A2h–DAA1h instruction stream and the documented zero/string/entry boundaries were used to author the code independently in NASM. No original executable bytes were embedded.
