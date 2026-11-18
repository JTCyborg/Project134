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

This phase note is superseded by the 2026-11-18 follow-up: `29F6h–2D10h` has since been emitted as NASM source. Subsequent verified additions cover `2D11h–2EF0h`, `2F24h–3043h`, and `3C5Ch–3F49h`. The next selected inherited executable interval is `3F4Ah–4230h`, called from `164Ch`.


## Follow-up verified on 2026-11-18

The source was subsequently extended beyond the original 29F5h stopping point. The 29F6h–2D10h Setup/configuration handler interval is already emitted by NASM. The memory benchmark/PIT routine at 2D11h–2DF4h and the two table-confirmed selectors at 2E74h and 2EB4h were added, followed by the Setup exit/temporary INT 13h path at 2F24h–3043h and the Setup menu/parser/formatter at 3C5Ch–3F49h. All of these additions are covered by the successful full-image comparison in run 44382969490.

The next inherited executable interval selected for reconstruction is 3F4Ah–4230h; its direct caller is 164Ch. The large inherited span 3044h–3C5Bh is retained pending a separate string/table boundary audit.
