# AMI486 — full-image cross-reference pass for Setup metadata (2026-11-17)

Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin`, fetched as a 65,536-byte binary image.

## Scope and method

Scanned the complete 64-KiB image for little-endian address operands and inspected candidate instruction contexts around `82B0` and `82C0–82E6`. A raw two-byte match is not automatically an instruction reference: code, immediate values and embedded data can produce false positives. The references below are separated into instruction-confirmed accesses and unclassified byte matches.

## Confirmed instruction-level references

### 1. Setup/configuration initializer at 0C54–0C73

The bytes decode as follows (16-bit real-mode x86, CS overrides shown explicitly):

- `0C54: 2E A1 C6 82` — load `AX = CS:[82C6]`.
- `0C58: A3 91 E1` — store AX to `DS:[E191]`.
- `0C5B: 8B 0E C8 82` — load `CX = CS:[82C8]`.
- `0C5F: 89 0E 93 E1` — store CX to `DS:[E193]`.
- `0C63: 2B C8` — subtract CX from AX.
- `0C65: F7 C1 E0 FF` — test CX against `FFE0h`; conditional branch follows.
- The alternate path reads `CS:[82BC]` and `CS:[82D2]`, storing values to `DS:[E197]` and `DS:[E195]`.
- `0C70: 2E 8B 1E CE 82` — load `BX = CS:[82CE]`.

This is a concrete data-flow link from the metadata words into the RAM workspace at `E191–E197`. It establishes that these words are consumed as configuration/state inputs. It does not yet tell us their user-facing labels or hardware meaning.

### 2. Indirect call through 82DE at 1C0A

- `1C08: 2E A1 DE 82` loads `AX = CS:[82DE]`.
- `1C0C: FF D0` executes `CALL AX`.

Thus `CS:[82DE]` is a function pointer (or callback slot) at this call site, not merely a numeric limit. Its initialized value in the ROM header is `19ADh`. The target bytes must be decoded in the context of this indirect-call convention before assigning a function name.

### 3. Indirect call through 82E2 at 1C58

- `1C58: 2E A1 E2 82` loads `AX = CS:[82E2]`.
- `1C5C: FF D0` executes `CALL AX`.

The initialized word is `19AEh`. This is a second callback slot, distinct from `82DE`.

### 4. Indirect jump through 82DA at 8A7A

- `8A7A: 2E A1 DA 82` loads `AX = CS:[82DA]`.
- `8A7E: BF 81 8A` sets `DI=8A81h`.
- `8A81: FF E0` jumps to `AX`.

The initialized value of `CS:[82DA]` is `19ABh`; the target bytes at `19AB` are `E7 C3`, i.e. `OUT imm8,AX` with immediate port `C3h`, followed by `RET` at `19AD`. This makes the odd target address deliberate: execution begins at byte `19AB`, not at a word-aligned boundary. This is strong evidence that the region around `19A2–19AF` is mixed pointer/data/code and must not be treated as a flat aligned word array.

## Confirmed references from earlier inspected paths

- `8306` and `83B0` read `CS:[82C6]` and walk 32-byte records.
- `8488` reads `CS:[82C0]`; `848D` reads `CS:[82C2]`.
- `85DE` reads `CS:[82B0]`; `85E9` reads `CS:[82CA]`; `85F1` reads `CS:[82C0]`.
- `0C54–0C73` adds confirmed reads of `82BC`, `82C6`, `82C8`, `82D2`, and `82CE`.
- `1C08`, `1C58`, and `8A7A` prove indirect control-flow use of `82DE`, `82E2`, and `82DA`.

## Unclassified raw matches

The byte scan also found occurrences of address-like byte pairs at `0C77`, `1C08`, `1C60`, `F4D3`, and other positions. Only the instruction contexts explicitly decoded above are promoted to confirmed references. For example, an occurrence of bytes `E6 82` can be an immediate port operand and must not be misreported as an access to memory address `8282`.

The candidate positions for `82CC`, `82D8`, `82DC`, and `82E0` did not yield a confirmed direct memory instruction in this pass. They may be reached indirectly through table pointers or may be data values.

## Corrections and cautions

1. The previous note described `19A2–19AF` as a compact sequence of near pointers too broadly. The bytes are mixed: at `19AB`, the ROM contains a valid executable entry `OUT C3h,AX; RET`; other bytes in this interval may be table entries or code reached at non-aligned offsets.
2. A header word containing `19A2h` is a pointer to the beginning of this mixed region; it does not mean that the first word at `19A2` is itself `19ABh`. At `19A2`, the raw bytes are `00 AB` (word `AB00h`). Preserve this distinction in future annotations.
3. The earlier claim that the consumer at `1A00` indexes `19B0` remains a direct byte-level observation, but its full semantic purpose is still not established.
4. No ALi1429 register meaning is assigned from these references alone.

## Next steps

1. Decode the callback targets `19AD` and `19AE` from their exact entry bytes, and enumerate all other indirect call/jump slots in the ROM.
2. Trace all writes to the RAM workspace `E191–E197` and identify downstream consumers.
3. Resolve the `82BC/82D2/82CE` values and their relationship to the callback path.
4. Reconstruct the `19B0` indexed table with its index source and all consumers.
5. Maintain a separate evidence ledger: confirmed direct read, confirmed direct write, indirect control-flow target, raw byte match, and unresolved.

## Evidence limits

This is a focused cross-reference pass, not a complete disassembly or runtime validation. Function names and chipset-register semantics remain intentionally unassigned where the bytes do not prove them.
