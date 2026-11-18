# Project134 byte-exact build audit

Date: 2026-11-18  
Branch: `main`  
Build workflow: [run 44375480780](https://github.com/JTCyborg/Project134/actions/runs/44375480780)

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

The committed `out/Debug/Project134.bin` is also byte-identical to `ami486.bin`. The generated `Project134.native-candidate.bin` has the same size and SHA-256.

## Native versus inherited coverage

The NASM listing `Project134.native-candidate.lst` was parsed for all `<bin NNh>` records emitted by `incbin`.

| Output origin | Bytes | Share |
|---|---:|---:|
| Explicit inherited `incbin` slices from `ami486.bin` | 60,623 | 92.50% |
| Bytes emitted directly by NASM source (instructions, explicit data, and fill) | 4,913 | 7.50% |
| Total | 65,536 | 100% |

There are 102 `incbin` directives in the listing, 17 of which contribute non-zero bytes. Zero-length slices are retained as explicit layout boundaries.

**Interpretation:** the result is a byte-exact, behavior-preserving compatibility image. It is not accurate to call 100% of the ROM independently reconstructed: 92.5% is inherited from the original reference. The byte comparison proves the assembled image matches the reference, not that every inherited routine has been semantically reconstructed.

## Test boundary

The GitHub Actions job installed NASM, assembled the candidate, ran the full byte comparison and checksum validator, verified the default boot image against the reference hash, and uploaded the artifacts. It did **not** launch PCem. Since the resulting candidate is byte-identical to the original ROM, it has the same ROM contents; a separate PCem launch remains an external runtime confirmation.

## Next reconstruction work

Replace inherited ranges with instruction-level NASM only when entry points, instruction boundaries, data tables, alternate entries, stack-threaded continuations, and side effects are supported by the existing disassembly evidence. Keep the full 65,536-byte comparison and POST checksum as regression gates. Never use a checksum-adjustment word to conceal missing or incorrect code.
