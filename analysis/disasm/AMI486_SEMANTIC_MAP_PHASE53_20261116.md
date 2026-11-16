# AMI486 semantic map — phase 53 (2026-11-16)

## Scope

Trace the provenance of the BP value saved at 5260h, including the branch at 5194h and the earlier POST test at 5DF7h.

## 1. 5260h saves the BP value inherited by the memory-test path

The sequence at 5189h is a stack-crafted transfer:

```asm
5189  push 5190h
518C  push FA4Eh
518F  ret
FA4E  pushaw
...
FA62  ret
5190  ...
```

The helper at FA4Eh pushes all general registers, validates an embedded byte sequence, and returns through the crafted continuation to 5190h. At 5194h the code tests BP with `OR BP,BP` and branches on the sign flag.

Two cases follow:

- If BP is nonnegative, execution enters 51F3h. It explicitly saves BP with PUSH BP, sets BP=1, runs the alternate memory-test path, and restores the original BP at 5239h with POP BP.
- If BP is negative, execution enters 5198h. That branch uses PUSH DX/PUSH BX and does not write BP. It returns to the common continuation at 523Eh with BP unchanged.

Both branches converge before the PUSHAW at 525Fh:

```asm
5238  pop dx
5239  pop bp             ; only on the nonnegative branch
...
525F  pushaw
5260  mov ax,sp
5262  mov [0067],ax
```

Therefore 5260h saves the BP value that was present at the 5194h sign test. The temporary BP=1 is not what gets saved on the nonnegative branch. On the negative branch BP is preserved directly.

## 2. The sign test is bit 15, not bit 13

At 5194h and again at 5DF7h the instruction is `OR BP,BP`; the conditional branch `JNS` tests SF, i.e. BP bit 15. This does not test BP.13.

At 5DF7h:

```asm
5DF7  or bp,bp
5DF9  jns 5E01
5DFB  mov word ptr [0072],1234h
```

A negative BP causes BDA word 0040:0072 to be set to 1234h. This is a separate observable consequence of the sign bit. It does not establish the value of BP bit 13.

## 3. BP flag accumulation before the 5260h save

The POST path in 5Dxx–5Fxx adds two low-order status bits to BP:

- 5F7D: `OR BP,0040h`, following the CMOS 94h test in 5F6C–5F7B.
- 5ECC: `OR BP,0080h`, following the display/mode condition in 5EBA–5ECA.

These instructions set BP bits 6 and 7 only. They preserve all other bits, including bit 13 and bit 15.

The inspected 5Dxx–5Fxx region does not initialize BP to a known constant. It pushes/restores BP around the call at 5DBD–5DC1, then later tests and ORs status bits into the inherited value.

## 4. The saved-frame conclusion

The BP word consumed by POPAW at 5289h is the BP word captured by PUSHAW at 525Fh. This phase shows:

1. the 51F3h branch restores the original BP before 525Fh;
2. the 5198h branch does not modify BP before the common continuation;
3. the later 5289h POPAW restores exactly that saved value.

Thus selector 3 is a transport/recovery path, not the source of BP.13. Selector 6 similarly restores a frame created by 546Ch, but its upstream frame producer is a separate path and is not conflated with 5260h.

## 5. What remains to be traced

The upstream producer of BP before the 5Dxx–5Fxx POST sequence remains unresolved. The current region only adds bits 6 and 7 and tests bit 15; it contains no instruction that sets BP.13.

Next trace:
- the actual entry into the 5Dxx POST sequence and BP value on entry;
- all earlier BP writes/stack restores on that caller chain;
- the separate PUSHAW frame at 546Ch used by selector 6;
- any indirect or stack-crafted route capable of entering 8400h.

## Confirmed vs unresolved

### Confirmed
- 5194h and 5DF7h test BP sign (bit 15), not bit 13.
- 51F3h temporarily sets BP=1 but restores the original BP at 5239h.
- 5198h branch leaves BP unchanged.
- 525Fh PUSHAW saves the inherited BP value after these branches converge.
- 5F7D and 5ECC set BP bits 6 and 7 only.
- A negative BP at 5DF7h causes BDA 0040:0072 to receive 1234h.

### Unresolved
- Which earlier POST caller supplies BP on entry to the 5Dxx sequence.
- Whether BP.13 is already set at that entry or is introduced by a stack restore / alternate entry.
- The independent producer of the frame saved at 546Ch.
- Any dynamic entry into 8400h.

The 64 KiB disassembly remains a linear decode, not a complete control-flow graph. The crafted RET transfers and alternate entry boundaries must be treated separately.
