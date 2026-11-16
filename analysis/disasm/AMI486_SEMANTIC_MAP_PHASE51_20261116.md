# AMI486 semantic map — phase 51 (2026-11-16)

## Scope

Phase 51 follows the CMOS 8Fh dispatch path at D615, examines the indexed near-jump table at D6A2, and rechecks whether its stock entries can explain an indirect entry to 8400h or the BP.13 state later tested at 5CF9h.

## 1. CMOS 8Fh is consumed as a dispatch selector

At D615 the BIOS selects CMOS index 8Fh, reads the byte, zero-extends it into SI, then clears CMOS 8Fh. The value is retained in SI while the BIOS changes segment state.

The first dispatch stage at D637 distinguishes values:
- 04h or 05h: prepares BX=0870h and uses the stack-crafted continuation at D650 through EEE7.
- 06h..0Ah: enters the D652 -> 8A20 path.
- Values above 0Ah: go to D724.
- Other values continue into the D652 path.

The separate D655 path has its own conditions and must not be conflated with the initial D637 selector tests.

## 2. Indexed jump table at D6A2

At D6A0 the code doubles SI, then executes:

```asm
D6A0  shl si,1
D6A2  jmp word ptr cs:[si-2958h]
```

Because the instruction is CS-relative and the displacement is signed 16-bit, the table base is D6A8h. The first 11 little-endian words in the ROM are:

| Selector | Table word | Near target |
|---:|---:|---:|
| 0 | D724 | D724 |
| 1 | 91D1 | 91D1 |
| 2 | F71E | F71E |
| 3 | 5280 | 5280 |
| 4 | F724 | F724 |
| 5 | F731 | F731 |
| 6 | 5486 | 5486 |
| 7 | 1B5B | 1B5B |
| 8 | 8A1D | 8A1D |
| 9 | 9206 | 9206 |
| 10 | F737 | F737 |

These are near offsets in the current CS, not far pointers. None of the 11 stock entries is 8400h. Selector values above 0Ah are rejected by the earlier range check on the path that reaches D6A2; the table must not be treated as an unrestricted 256-entry vector.

Important reachability qualification: the table is proven as the operand of the indirect jump at D6A2, and its bytes/targets are decoded. This alone does not prove that every selector can reach D6A2 through the earlier branch structure; the D637 and D655 paths are distinct.

## 3. Relation to BP.13

The table contains entries to several distant BIOS regions, including 91D1, F71E, 5280, 5486, 1B5B and 9206. This provides concrete candidate paths for further tracing, but the table words themselves do not encode or initialize BP.

The selector-8 entry targets 8A1D, not 8400h. No table entry points to 8400h. The D74C route remains as established in phase 50: BP is cleared at D743 and only bits 12 and 15 are set later on that branch.

No new producer for BP.13 is established in this phase.

## 4. Conclusions

### Confirmed

- CMOS 8Fh is read at D61D and cleared at D629 before the value is used as selector SI.
- The indexed jump at D6A2 reads from a table based at D6A8h.
- The first 11 table words are the exact near offsets listed above.
- No one of these stock table entries targets 8400h.
- The D74C initialization path still cannot set BP.13.

### Unresolved

- Full semantic purpose and caller reachability of each D6A2 table target.
- Whether one of the candidate targets restores a caller-supplied BP value that later reaches 5CF9h.
- Any alternate runtime or externally supplied entry into 8400h.

The listing is a linear decode. Table bytes and alternate entry points are analyzed as data/control-flow operands where proven; a complete CFG is still outstanding.
