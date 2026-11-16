> **Erratum (phase 49):** The paragraph below describing `LES SI` at `5C6A` is superseded. Because the stack-crafted RET returns to `5C68`, the successful branch resumes at `5C6A` with a shifted instruction boundary: `MOV AL,23h; OUT 80h,AL; XOR byte [BP+DI],C0h; MOV ES,AX; MOV AL,40h; MOV DS,AX; MOV AL,30h; MOV SS,AX; MOV SP,0100h; CALL 1B5Eh; IN AL,60h`. The final zero-pattern scan in `552A` leaves AX=0000h, so the resulting segments are ES=`0023h`, DS=`0040h`, SS=`0030h`. No LES executes on this path. See [phase 49](AMI486_SEMANTIC_MAP_PHASE49_20261116.md) for the full corrected decode.

# AMI486 semantic map — phase 48 (2026-11-16)

## Scope

Reconstructed the stack-crafted continuation around `5C50–5C8C`, including the return path from the full-segment memory test at `552A`. Rechecked static control transfers and indirect dispatch candidates around `8400`. This remains a static ROM analysis; runtime register values and dynamically supplied stack contents are distinguished from constants.

## 1. `5C50–5C6F`: stack-restored memory-test continuation

### First stack transition

At `5C50`:

- `MOV SP,5C56`
- near jump to `F5A9`
- `F5A9` reads port `61h`, ORs `0Ch`, writes it, ANDs `F3h`, and writes it again; it then RETs.
- The helper does not preserve AL. Its port writes pulse bits 2–3 of port 61h; no timer or delay loop is present in this helper itself.

Execution resumes at `5C56`:

- `POP AX` reads the ROM word at `5C56` = `5C58h`.
- `POP SP` then reads the word at `5C58` = `ED0Bh`, replacing SP with `ED0Bh`.
- `OR BP,BP` tests the inherited BP value; `JS 5C1E` branches only if BP bit 15 is set.

The `POP SP` does not transfer execution to `5C58`; IP is already advancing there. The instruction at `5C58` is the `OR BP,BP` just described.

### Second stack transition and return from `552A`

If BP is nonnegative, code reaches `5C60`:

- `MOV SP,5C66`
- near JMP to `552A`

Routine `552A–5571` is a 32-KiB word-pattern memory test over `ES:0000–ES:FFFF` (CX=`8000h` words). It writes and verifies patterns `8080h`, `5555h`, `3333h`, and `0000h`. Each verify uses `REPE SCASW`; a mismatch branches to the common RET at `5571`.

The RET consumes the word at `SS:5C66`. ROM bytes there are `68 5C`, so the actual return IP is `5C68h` (the immediate operand `755Ch` of the instruction beginning at 5C66 is not the return target).

At `5C68`, bytes `75 C4` are `JNZ 5C2Eh`. Thus:

- If the last pattern comparison failed (ZF=0), return branches to the memory-test failure path at `5C2E`.
- If the complete pattern test passed (ZF=1), execution falls through at `5C6A`.

This establishes a real stack-crafted control-flow edge from `552A` back into the middle of the byte sequence at `5C66`; the instruction stream from `5C68` is not the same as the linear decode beginning at `5C69`.

### Successful continuation

On the successful comparison path, `5C6A` begins with `LES SI,[BX+SI-19DDh]`, followed by `XOR byte [BP+DI],C0h` at `5C6E`. At `5C70` the stream sets:

- ES from AX (AX was loaded by LES),
- DS = `0040h`,
- SS = `0030h`,
- SP = `0100h`.

It then calls the RET stub at `1B5Eh`, reads port `60h`, and continues through the POST keyboard-controller checks at `5C8C).

## 2. BP provenance and the bit-13 test

The successful RAM-test path does not initialize BP in the visible `5BF8–5C8C` sequence. The only explicit `MOV BP,3` in this path is at `5C37`, reached from the memory-test failure handler before jumping to the diagnostic path at `F4A5`.

Therefore:

- `5C58 OR BP,BP` tests the sign bit (bit 15), not bit 13.
- If BP is negative, the flow returns to `5C1E`; otherwise it performs the 32-KiB pattern test.
- The later `5CF9 TEST BP,2000h` independently tests bit 13. This phase does not identify the successful-path producer of that bit.
- The stack reset to `ED0Bh` changes SP, not BP; it does not explain BP bit 13.

The origin of BP bit 13 remains unresolved. The earlier conclusion that the success path carries inherited BP remains valid, now with the exact intervening stack operations established.

## 3. Indirect-entry audit for `8400h`

The known direct entries remain:

- `8408h -> D90Dh` (from the branch at 8406h),
- `84C8h -> D90Dh` (from the terminal record-walk path).

No direct CALL/JMP to `8400h` was found in the byte-covering linear instruction listing. The code at `8400h` begins immediately after the RET at `83FFh`, so ordinary fall-through from the record walker is not a valid explanation.

The scan confirms that the ROM contains several computed CALL/JMP and far-dispatch forms elsewhere, but no proven pointer/table value targeting `8400h` has yet been tied to a live caller. The `8400h` indirect-entry hypothesis therefore remains open, not confirmed.

## 4. Status after phase 48

### Newly confirmed

- Exact stack mechanics at `5C50–5C58`, including the value loaded into SP (`ED0Bh`).
- `552A` is a 32-KiB word-pattern write/verify routine.
- Its stack-supplied RET target is `5C68h`, not `755Ch`.
- The ZF state from the final `SCASW` comparison selects failure (`5C2E`) versus successful continuation (`5C6A`).
- The success continuation sets ES from a far pointer, DS=`0040h`, SS=`0030h`, SP=`0100h`, then enters the keyboard-controller check sequence.
- BP sign test at `5C58` is distinct from the BP bit-13 test at `5CF9`.

### Still unresolved

- Runtime source/value of BP bit 13 on the successful POST path.
- The live indirect caller or pointer-table entry for `8400h`.
- Runtime values used by the far pointer consumed by `LES SI` at `5C6A`.
- Exact semantic role of the `XOR [BP+DI],C0h` operation at `5C6E`.

This report supplements earlier phases; it does not turn the complete linear decode into a complete control-flow graph.
