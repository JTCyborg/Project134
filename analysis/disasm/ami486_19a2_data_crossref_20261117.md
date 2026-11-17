# AMI486 ROM — cross-reference of 19A2–1A8E data and 1A00 consumer

Date: 2026-11-17  
Target: `ami486.bin`, Project134/main  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.

## Why this range was inspected

The Setup metadata at `82C0–82E6` contains repeated near offsets into the `19A2–1A8E` region. This pass checks the actual target bytes and follows the visible consumer beginning at `1A00`, rather than assigning meanings from pointer values alone.

## Byte-level findings

### 1. Mixed code/data boundary

The bytes around `1980–19A1` contain short I/O helper routines ending in `C3` returns. Immediately after them, `19A2–19AF` contains a compact sequence of unaligned little-endian words and executable-looking bytes:

```
19A0: C4 C3 00 AB 19 AD 19 AE 19 AF 19 FF E7 C3 C3 C3
19B0: 20 00 80 00 00 01 00 02 40 00 00 01 00 02 00 04
19C0: 00 00 10 14 19 21 28 32 42 20 4B 42 20 43 41 43
19D0: 48 45 20 4D 45 4D 4F 52 59 0D 0A 00 4D 48 7A 20
19E0: 43 50 55 20 43 6C 6F 63 6B 0D 0A 00 4D 48 7A 20
19F0: 44 58 32 20 43 50 55 20 0D 0A 00 B8 18 18 E8 CE
```

The boundary must therefore be treated as mixed code/data until instruction reachability and all incoming references are resolved. A linear disassembler alone can misclassify the embedded words or text.

### 2. Pointer targets visible in the header

The following words are present in the `82C0–82E6` region and land inside or immediately adjacent to this mixed region:

- `82CC = 19A2`
- `82CE = 19A2`
- `82D8 = 19A3`
- `82DA = 19AB`
- `82DC = 19A5`
- `82DE = 19AD`
- `82E0 = 19A7`
- `82E2 = 19AE`
- `82E4 = 19A9`
- `82E6 = 19AF`

These are confirmed stored values. Their individual roles are not yet named. In particular, offsets such as `19A3`, `19A5`, `19A7`, and `19A9` are odd and overlap the byte alignment of the apparent word sequence; do not silently normalize them to even offsets.

### 3. Consumer at 1A00

The routine at `1A00` begins with a near call and then tests status/condition flags before processing the table:

- `1A0C: BE B0 19` loads `SI=19B0`.
- `1A0F: 03 F0` adds `SI) to `SI), selecting a word by an index already held in `SI`.
- `1A12: 2E 8B 04` reads a word through the code-segment override from the selected table location.
- It then calls a helper at a relative target and separately loads `SI=19C9`, followed by another helper call.
- Later it loads `SI=19C2`, performs another indexed access, and references `19EC` and `19DC` as further data/string bases.
- The routine contains multiple conditional branches and a short loop/return structure through approximately `1A8E`.

This directly ties `19B0` and the string area `19C2–19F2` to an active BIOS routine. It does not yet prove that every pointer in `82C0–82E6` is consumed by this one routine.

### 4. Readable strings

NUL-terminated text at `19C9` onward includes:

- `KB CACHE MEMORY\r\n`
- `MHz CPU Clock\r\n`
- `MHz DX2 CPU \r\n`

The text establishes that this code/data area participates in CPU/cache reporting or setup display. It is not sufficient by itself to assign exact meanings to every numeric table entry at `19B0`.

## Consequences for the 82C0 investigation

1. The `82C0–82E6` area is a set of distinct words, not one homogeneous four-byte array.
2. Some stored values point into the mixed region at `19A2–19AF`; the targets include odd byte offsets and need byte-accurate interpretation.
3. `19B0` is a word table actively indexed by code at `1A00`.
4. `19C2–19F2` contains user-visible text consumed by the same routine.
5. The Setup record walker and the CPU/cache display routine may share pointer metadata, but that relationship must be proven from callers and data flow rather than inferred from proximity.

## Next concrete work

- Trace every direct and indirect read of `CS:[82B0]` and `CS:[82C0–82E6]`, plus writes to those locations.
- Decode all incoming control-flow edges to `19A2–19AF` to separate executable entry points from unaligned pointer bytes.
- Reconstruct the `19B0` word table and identify the index source feeding `1A0F`.
- Follow the helper calls from `1A00` and map which string/table entries they consume.
- Only after this, assign names to fields and connect them to the Setup UI records.

## Evidence limits

This note records byte values, visible instruction references and readable strings. It does not claim a complete CFG, complete cross-reference database, verified runtime values, or final semantic labels for the table fields.
