# Project134 byte-exact build audit

Date: 2026-11-18  
Branch: `main`  
Build workflow: [run 44382969490](https://github.com/JTCyborg/Project134/actions/runs/44382969490)

## Verified build result

The NASM candidate produced by `bios/tools/build_bios.ps1` was compared byte-for-byte with the immutable `ami486.bin` reference.

| Check | Result |
|---|---:|
| Candidate size | 65,536 bytes |
| Reference size | 65,536 bytes |
| Differing bytes | **0** |
| 16-bit little-endian ROM word sum | `0000h` |
| Candidate SHA-256 | `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b` |
| Reference SHA-256 | `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b` |
| Workflow result | success |

The build log explicitly reports:

- `FULL ROM BYTE COMPARISON PASS: 65536/65536 bytes match ami486.bin.`
- `BIOS POST06 ROM checksum PASS (16-bit sum = 0000h).`
- `NASM BIOS structural validation PASS: 65536 bytes`.

The committed `out/Debug/Project134.bin` and generated `Project134.native-candidate.bin` are both byte-identical to the reference. The CI job did **not** launch PCem.

## Native versus inherited coverage

The NASM listing `Project134.native-candidate.lst` from run `44382969490` was parsed for all `<bin NNh>` records emitted by `incbin`.

| Output origin | Bytes | Share |
|---|---:|---:|
| Explicit inherited `incbin` slices from `ami486.bin` | 55,961 | 85.39% |
| Bytes emitted directly by NASM source (instructions, explicit data, and fill) | 9,575 | 14.61% |
| Total | 65,536 | 100% |

The listing contains 103 `<bin>` records, 18 of which contribute non-zero bytes. Zero-length slices are retained as explicit layout boundaries.

**Interpretation:** the output is a byte-exact compatibility image, but only 14.61% of its bytes are currently emitted directly by NASM source. The remaining 85.39% are inherited from the original reference through explicit slices. Byte equality proves the assembled image matches the reference; it does not prove the inherited routines have been semantically reconstructed.

## Newly verified source regions

The latest source and listing include these regions as NASM instructions/data rather than inherited slices:

| ROM interval | Contents |
|---|---|
| `2065h–2F23h` | POST memory/CMOS paths, Setup selectors, memory benchmark, PIT helpers, and Setup relocation handoff |
| `2F24h–3043h` | Setup exit prompt strings and handlers, BDA clear helper, temporary IVT/INT 13h AH=14h path |
| `3C5Ch–3F49h` | Setup main menu, shared menu/header renderer, value parser, and metric formatter |
| `8300h–83FFh` | CPU/cache profile selector and CMOS 8Eh update path |

The Setup handler table at `B7B2h` contains 14 near-offset entries. The earlier analysis note omitted `2EB4h`, shifting the later table entries; that transcription has been corrected. The two selector handlers at `2E74h` and `2EB4h` now have instruction-level source.

The `2D11h–2DF4h` benchmark block was reconstructed from the ROM instruction stream. Its caller/entry provenance remains unresolved; its code bytes nevertheless match the reference exactly. The `2E74h` and `2EB4h` Setup handlers are confirmed by the pointer table at `B7B2h`.

## Test boundary

GitHub Actions run `44382969490` installed NASM, assembled the candidate, ran the full byte comparison and checksum validator, verified the default boot image against the reference hash, and uploaded the artifacts. It did **not** launch PCem. A separate PCem boot and runtime differential trace are still required.

## Next reconstruction work

The next selected inherited executable interval is `3F4Ah–4230h`, called directly from `164Ch` during POST. It contains the system-configuration display routine and its helpers. Preserve the adjacent strings/data beginning at `4231h` until their boundaries are independently mapped. Continue using full-image byte comparison and POST checksum as regression gates; never add a checksum-adjustment word to conceal missing or incorrect code.
