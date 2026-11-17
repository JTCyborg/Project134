# AMI486 — consumers of E191–E197 and configuration menu titles

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin` (65,536 bytes; fetched blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

## 1. Configuration branches select menu headings

The three branches beginning at `0BE7`, `0C0E`, and `0C35` compare global state words at `B7CA`, `B7CC`, and `B7CE` against zero. Each branch sets workspace words and passes a pointer to a visible menu title:

| Branch | Title pointer | Text at target |
|---|---:|---|
| `0BE7` | `305B` | `ADVANCED CMOS SETUP` |
| `0C0E` | `3071` | `ADVANCED CHIPSET SETUP` |
| `0C35` | `308A` | `POWER MANAGEMENT SETUP` |

The surrounding string table continues with `PERIPHERAL MANAGEMENT SETUP` at `30A4`. The code at `0BE7–0C50` is therefore part of Setup-menu selection/initialization, not direct ALi1429 register programming by itself.

Each branch initializes:
- `DS:[E191]` and `DS:[E193]` with branch-specific limits/ranges;
- `DS:[E195]` with `B7B2` (a pointer into a small table near `B7B0`);
- `DS:[E197]` with a pointer to a per-menu item/descriptor table near `305B`, `3071`, or `308A`.

The exact structure of those descriptor tables is not fully decoded yet.

## 2. E191/E193/E195/E197 are consumed by the Setup UI engine

The code at `5FE0–6132` reads the workspace directly:

- `5FE7: 8B 1E 91 E1` — `BX = [E191]`; this is copied into `[E18F]`.
- `600C: 8B 1E 8F E1` — reads the current position/state from `[E18F]`.
- `6011: 3B 1E 93 E1` — compares that value against `[E193]`, establishing `E193` as an upper-bound/limit in this path.
- `60A7: 8B 36 95 E1` — `SI = [E195]`; subsequent `MOV BX,[SI]` and `CALL BX` dispatch through a word in the selected table.
- `6128: 8B 1E 97 E1` — `BX = [E197]`; the code then increments BX by two and walks word-sized entries, calling a helper for each item.

This is a strong structural result: the four workspace words form a Setup menu descriptor:
- `E191`: initial/current index or starting position (copied to `E18F`);
- `E193`: upper bound / item count limit;
- `E195`: pointer to a callback/handler table;
- `E197`: pointer to a word array of menu item descriptors.

The labels “initial/current index” and “upper bound” are based on the observed arithmetic/comparison behavior; exact inclusive/exclusive convention remains to be confirmed.

## 3. The handler table at B7B2

The bytes at `B7B0–B7CF` are not plain option text. They contain compact values and near offsets, for example:

```
B7B0: 00 0C 74 2E B4 2E DB 86 F6 29 C1 2A 13 2B 4C 2B
B7C0: 91 2B D3 2B 1D 2C 69 2C CF 2C 84 05 A5 08 00 00
```

The `E195` pointer is set to `B7B2`, and the UI engine reads a word through `[SI]` at `60A7–60B0` before calling it. This indicates a dispatch table of handler addresses or offsets. Because the table's first entries are odd and some values look like offsets, determine whether they are relative offsets, segment-relative addresses, or packed fields by following the exact helper call convention. Do not label them as absolute near function pointers yet.

## 4. Updated structural model

The previously ambiguous metadata now resolves into a coherent two-layer Setup path:

1. BIOS selects a menu family (CMOS, chipset, or power management) based on state flags at `B7CA/B7CC/B7CE`.
2. It initializes a menu descriptor in `E191–E197`.
3. The generic UI engine at `5FE0–6132` uses the descriptor to maintain selection, enforce bounds, dispatch the current setting handler, and enumerate menu entries.
4. The lower-level setting handlers still need to be decoded before attributing any entry to a specific ALi1429 register.

## 5. Important unresolved questions

- Are `E191/E193` a first index and an exclusive upper bound, or a start/end pair?
- Are `B7B2` entries absolute offsets, relative offsets, or a compact handler encoding?
- Which helper at `60A7` invokes the selected handler and what register/stack convention does it use?
- What exact structure is stored in the menu item array addressed by `E197`?
- Which menu entries perform chipset I/O, and which are merely UI choices?

## 6. Next actions

1. Decode the helper called at `60B0` and its callee convention.
2. Decode each handler/offset referenced by the B7B2 table.
3. Decode the descriptor words addressed by E197 for each menu title.
4. Map each setting handler's I/O sequence and only then assign chipset-register names.
5. Search for writes to the global state flags `B7CA/B7CC/B7CE` to understand menu selection state.

## Evidence limits

Direct memory operands and strings above are confirmed from the ROM bytes. The menu-descriptor interpretation is strongly supported by cross-references, but individual handler semantics and chipset register mappings remain unresolved.
