# AMI486 — callback target validation and E191–E197 initialization

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input image: `ami486.bin`, 65,536 bytes, fetched from main (blob SHA: `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

## 1. Validate callback targets at 19AD and 19AE

The exact bytes are:

```
19A0: C4 C3 00 AB 19 AD 19 AE
19A8: 19 AF 19 FF E7 C3 C3 C3
```

Therefore:
- `19AB: FF E7` decodes as `JMP DI` (register-direct near indirect jump).
- `19AD: C3` decodes as `RET`.
- `19AE: C3` decodes as `RET`.
- `19AF: C3` decodes as `RET`.

The indirect call sites load `CS:[82DE]` (initialized to `19AD`) and `CS:[82E2]` (initialized to `19AE`), then execute `CALL AX`. Both currently resolve to one-byte return stubs. Their observed effect at these ROM bytes is a no-op callback returning to the caller. This does not prove the words are immutable under all configurations, but the inspected image initializes them to RET stubs.

### Correction to the previous report

The previous note incorrectly described `19AB` as `OUT C3h,AX`. That was a decode error. The actual bytes are `FF E7`, i.e. `JMP DI`. The report must not be used with the earlier OUT interpretation.

## 2. The 82DA trampoline is a special case

At `8A78`:

```
2E A1 DA 82    MOV AX,CS:[82DA]
BF 81 8A       MOV DI,8A81
FF E0          JMP AX
```

The initialized `CS:[82DA]` value is `19AB`. Execution at `19AB` performs `JMP DI`, so the control flow then targets `8A81`.

Important caveat: `8A81` is the second byte of the instruction beginning at `8A80` (`FF E0`). Entering there means the CPU decodes from the middle of the preceding instruction. This is intentional-looking overlapping instruction flow, but its final semantics must be traced through the subsequent byte stream and flags/register state; do not label it a normal function callback. Preserve the exact control-flow edge:
`8A78 -> 19AB -> 8A81`.

## 3. E191–E197 workspace: initialization writes

The initialization code at `0BE7–0C73` writes the following words:

| Destination | Source / operation visible in code | Site |
|---|---|---|
| `DS:[E191]` | `CS:[82C6]` | `0C54–0C5A` |
| `DS:[E193]` | `CS:[82C8]` | `0C5B–0C62` |
| `DS:[E195]` | `CS:[82D2]` on one branch | `0C6E–0C75` |
| `DS:[E197]` | `CS:[82BC]` on one branch | `0C68–0C6D` |

The code computes `AX-CX` after loading `82C6` and `82C8`, and tests `CX & FFE0h`. When the test condition selects the alternate path, it loads `82BC` and `82D2` into the remaining workspace slots. This appears to be a normalization/selection step between two configuration layouts, but exact semantic labels are not yet proven.

The same destination words also appear in earlier routines at `0BE7–0C50`. Those routines compare global words at `B7CA`, `B7CC`, and `B7CE` against zero, then populate the workspace with fixed constants and call helpers. The three branches are structurally similar but use different constants:
- first branch initializes `E191/E193/E195/E197` with `B7D0`, `BD54`, `B7B2`, and a pointer to a table near `305B`;
- second branch uses `BD54`, `C5F9`, `B7B2`, and a table near `3071`;
- third branch uses `C5F9` for both first fields, `B7B2`, and a table near `308A`.

These values are copied as immediates/ROM constants in the visible instructions; do not equate them directly with ALi1429 register numbers without following the helper routines and their consumers.

## 4. 19B0 indexed table — exact contents

The 16 words beginning at `19B0` are:

```
0020 0080 0100 0200 0040 0100 0200 0400
```

Following bytes at `19C0` begin:
```
00 00 10 14 19 21 28 32 42 20 4B 20 43 41 43 48 ...
```

The code at `1A0C` sets `SI=19B0`, then adds twice an index already in SI before reading a word with a CS override. This confirms word-indexed table access. It remains necessary to identify the index source and the consumer helper before assigning meanings such as cache size, memory size or CPU frequency.

## 5. Confirmed control-flow / metadata summary

- `82DE -> 19AD -> RET`: optional no-op callback in this image.
- `82E2 -> 19AE -> RET`: second optional no-op callback in this image.
- `82DA -> 19AB -> JMP DI`: trampoline path, not a normal function body.
- `82C6/82C8/82BC/82D2/82CE`: loaded by the initializer into or alongside the E191–E197 workspace.
- `82C0/82C2/82CA`: previously confirmed in the record/table consumers at `8488/848D/85E9`.

## 6. Next actions

1. Decode the helpers called from `0BE7–0C50` and `0C78`; establish how `E191–E197` is consumed.
2. Follow the code at the computed entry `8A81` with overlapping-instruction-aware control flow.
3. Find all writes to `82DA/82DE/82E2` (if any) and determine whether callbacks are patched at runtime.
4. Resolve the index used by `1A0C–1A13` and all callers of the helper at `1A12`.
5. Keep hardware register naming provisional until the helper-level I/O sequence is proven.

## Evidence limitations

The bytes and direct operands above are confirmed from the fetched image. The functional interpretation of the workspace, the computed branch through `8A81`, and the `19B0` table remains incomplete. No runtime trace or ALi1429 register mapping is claimed.
