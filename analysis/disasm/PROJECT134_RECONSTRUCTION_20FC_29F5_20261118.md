# Project134 reconstruction phase: 20FCh–29F5h

Date: 2026-11-18  
Branch: `main`  
Verified build: [GitHub Actions run 44378354650](https://github.com/JTCyborg/Project134/actions/runs/44378354650)

## Implemented address ranges

The previous single inherited slice beginning at `20FCh` has been split into NASM source through `29F5h`. The new source preserves the original offsets and instruction encodings.

| Range | Reconstructed content |
|---|---|
| `20FCh–2409h` | Low/high memory alias probes, sentinel writes, stack-threaded chipset register updates, CR0 transition and continuation into memory initialization |
| `240Ah–2536h` | Shadow-window selection/copy helpers and CMOS-weighted ALi register conversion |
| `2537h–2628h` | AUTO Config ALi register handlers and CMOS/BDA row-offset selector |
| `2629h–26F8h` | Segment sweeps, temporary GDT/GDTR, protected-mode copy helper |
| `26F9h–284Fh` | Extended-memory POST probe, chipset configuration, restoration of the saved DS/ES/SS:SP frame |
| `2850h–29F5h` | Memory-size measurement, PIT timing helper, memory clearing and RAM pattern test |

The CPU/cache profile selector at `8300h–83FFh` remains a separate verified native-source region.

## Important control-flow/data distinctions

- The words at `2236h`, `2242h`, `224Eh`, `2394h`, `23AAh`, `23B6h`, `23CEh`, `23DAh`, `27CAh`, `27DAh`, `27F2h`, `27FEh`, `280Ah`, `2816h`, `2828h`, and `2834h` are stack-threaded continuation words, emitted as data rather than decoded as ordinary instructions.
- The GDT/GDTR area at `2646h–2685h` is emitted as data. The protected-mode transition code starts at `2686h`.
- Several memory probe instructions use explicit opcode bytes to preserve 32-bit address/operand prefix order and original register-direction encodings.
- The PIT and chipset helpers return through DI-based continuation entries. Their jumps to `296Bh` and other shared helpers are distinct from the saved DI return destinations.
- The RAM pattern retry re-enters at `29C6h`, after loading AX with the first pattern; it must not restart at `29C3h`.

## Verification

Run `44378354650` completed successfully. The assembled candidate:

- is exactly 65,536 bytes;
- matches `ami486.bin` at every byte;
- has a 16-bit ROM word checksum of `0000h`;
- passes the CPU/cache profile byte comparison;
- produces the same SHA-256 as the original reference.

This is a byte-identity/build result, not a PCem runtime test. The source still uses explicit inherited slices for the not-yet-reconstructed regions after `29F5h`.

## Next target

The next inherited byte begins at `29F6h`. It contains setup/configuration handlers, CMOS-backed field selection, and inline pointer/offset tables. The table data and stack/indirect call conventions must be mapped before converting the block.
