# AMI486 semantic map — phase 54 (2026-11-16)

## Scope

Trace the value tested at 5CF9h back through the stack-crafted memory-test continuation, and distinguish the BP-preserving 546Ch frame from the separate 525Fh frame.

## 1. 5CF9h is reached with BP inherited from the memory-test path

The sequence 5C04h–5C60h performs a destructive memory test and uses crafted stack continuations. The important control point is:

```asm
5C50  mov sp,5C56
5C53  jmp F5A9
5C56  pop ax
5C57  pop sp
5C58  or bp,bp
5C5A  js 5C1E
...
5C60  mov sp,5C66
5C63  jmp 552A
```

If BP is negative, 5C1Eh sets SP=5C24h and jumps to 5520h. The RET at 5529h consumes the crafted word at 5C24h, restoring SP to 5C26h, then execution continues at 5C6Ah.

If BP is nonnegative, 5C60h sets SP=5C66h and jumps to the memory-pattern test at 552Ah. Its RET at 5571h consumes the crafted word at 5C66h and resumes at 5C68h, which flows through the short continuation into 5C70h.

Both paths converge at the 5C6Ah/5C70h setup without an explicit BP write. The earlier 5C58h `OR BP,BP` tests bit 15 only; it does not modify BP.

## 2. The 5C70h–5CF9h path preserves BP

After the stack continuation, the code sets ES, DS=0040h, SS=0030h and SP=0100h, then runs the keyboard-controller checks.

Relevant BP instructions in this path:

- 5C8Ch: `TEST BP,1000h` — tests BP bit 12.
- 5CC6h: `OR BP,0` — no-op on the value; it only updates flags.
- 5CF0h: `OR BP,0` — same no-op.
- 5CF9h: `TEST BP,2000h` — tests BP bit 13.
- 5D07h: `AND BP,EFFFh` — clears BP bit 12, not bit 13.

Thus the bit-13 decision at 5CF9h is based on a value inherited through the crafted memory-test path. The keyboard-controller logic does not set BP.13. If BP.13 is set, 5CFF–5D04 sends the 8042 command/data sequence and transfers to D604h. If it is clear, execution falls through 5D07h and clears bit 12.

## 3. Consequence: the source is earlier than 5C04h

The inspected 5C04h–5CF9h path contains no instruction that sets BP.13. The only direct BP assignment in the nearby memory-test code is 5C37h `MOV BP,3`, which is on the memory-test error path and immediately jumps to the fatal alarm routine F4A5h. It is not the successful path that reaches 5CF9h.

Therefore the BP.13 producer must be upstream of the 5C04h memory test, or supplied by a stack restore / alternate entry that establishes BP before this code.

The earlier 5BF8h path uses SP=5C02h and jumps to F5A9h; F5A9h returns through the crafted continuation at 5C02h. This path also does not write BP. The only statically visible jump into 5BF8h in the linear listing is from DA9Fh, but the earlier analysis has not established a valid runtime entry into DA9Fh. Do not treat that as a proven caller chain.

## 4. Separate 546Ch PUSHAW frame

The 546Ch routine is called from at least 51FEh, 5403h and 541Ah:

```asm
546C  pushaw
546D  mov ax,sp
546F  mov [0067],ax
...
5486  mov ax,[0067]
5489  mov sp,ax
...
5493  popaw
```

This frame captures the BP value present at each caller. The 5486h selector-6 recovery path restores the last saved frame, but the frame producer is caller-dependent: the 51FEh, 5403h and 541Ah call sites execute in different memory-test/loop contexts. It is not the same frame as the one saved at 525Fh.

## 5. Confirmed vs unresolved

### Confirmed
- Both crafted memory-test continuations converge into the 5C70h setup without changing BP.
- 5C58h tests BP bit 15; 5C8Ch tests bit 12; 5CF9h tests bit 13.
- 5CC6h and 5CF0h `OR BP,0` do not set any BP bit.
- 5D07h clears bit 12 only.
- 5C37h sets BP=3 only on the fatal memory-test error path.
- 546Ch saves the caller's BP in a separate PUSHAW frame; callers include 51FEh, 5403h and 541Ah.

### Unresolved
- Which valid runtime entry reaches the 5C04h memory-test sequence and what BP is supplied there.
- Whether a stack restore before 5C04h supplies BP.13.
- Whether DA9Fh is a genuine runtime predecessor of 5BF8h.
- Which 546Ch caller is associated with selector 6 at the time the saved BDA pointer is consumed.

The disassembly remains a linear decode; the stack-crafted continuations described above are based on the concrete SP setup and RET destinations, not on ordinary sequential fall-through.
