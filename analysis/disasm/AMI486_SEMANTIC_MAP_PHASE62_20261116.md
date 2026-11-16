# AMI486 semantic map — phase 62 (2026-11-16)

## Scope

Audit the BP preservation of the helpers between 509Eh and 5194h, with special attention to INT 15h/AH=89h, F3DB, 5506h, and the memory-test routines.

## 1. INT 15h/AH=89h dispatch and handler preserve BP

The INT 15h dispatcher at 9220h selects its handler through CS:[90BAh + 2*index]. For AH=89h, index=09h and the table entry is 933Ah.

The dispatcher itself protects BP while using it as a temporary table pointer:

```asm
9220  call 8AE8
...
9236  push bp
9237  mov bp,ax
9239  mov ax,cs:[bp]
923D  pop bp
923E  jmp ax
```

Handler 933Ah does not write BP:

```asm
933A  cli
933B  push cx
933C  call F66A
933F  pop cx
9340  pop ax
9341  jne 9372
9343  call EEEF
9346  push es
9347  pop ds
9348  pop ax
9349  add sp,2
934C  push 30h
934E  push ax
934F  lgdt [si+8]
9353  lidt [si+10h]
9357  smsw ax
935A  or al,1
935C  lmsw ax
...
9376  retf 2
```

The two helpers called by this handler are also BP-neutral in their complete inspected bodies:
- F66Ah writes 8042 command/data values and uses AX/CX; no BP reference or write.
- EEEFh initializes PIC masks through AL/BL/BH and I/O; no BP reference or write.

The successful AH=89h path changes control registers and segment registers, but it does not alter BP. The dispatcher temporarily pushes BP and restores it before jumping to 933Ah. Thus this INT 15h path preserves BP.

## 2. F3DB and the screen-output helpers preserve BP

At F3DBh:

```asm
F3DB  pushaw
...
F3E0  int 10h
...
F3F0  int 10h
F3F4  int 10h
...
F409  popaw
F40A  ret
```

PUSHAW/POPAW bracket the video BIOS calls and the local checksum/character loop. BP is saved and restored, so INT 10h side effects cannot leak into the caller's BP.

The failure branch at F40Bh may call 8649h and return through F402h/F409h; it remains inside the same saved-register frame.

F419h is a separate PUSHAW/POPAW validation helper. It also preserves BP.

## 3. Remaining local helpers are BP-neutral

The path around 509Eh–5194h uses these helpers:

- 5506h: tests byte [0012h], optionally writes PIC mask to port21h, STI, RET. No BP access.
- 5305h: stores AL/AH to the probe descriptor and performs memory writes/reads using SI, ES, DI, CX, AX. No BP access.
- 534Ch: writes/checks the byte pattern and updates the descriptor through SI; no BP access.
- 5371h: increments DX and scans memory through ES:DI; no BP access.
- 53A6h: saves AX and DI, performs memory reads/writes and calls F5A9h; no BP access.
- 5506h's path does not call another BP-writing helper.
- FA4Eh was previously decoded as PUSHAW-protected validation code; its saved register frame preserves BP.

The memory-test branches around 5198h–523Eh were separately checked in phases 53–54: their stack-crafted continuations and tests do not write BP on the successful paths. The nonnegative path's temporary BP=1 is explicitly undone at 5239h.

## 4. Stronger provenance boundary

With the INT 15h handler and the local helpers accounted for, the previous uncertainty is narrowed:

- The code from 509Eh through the convergence at 523Eh contains no identified BP-changing operation on the successful path, except the temporary BP=1 on the nonnegative branch, which is restored at 5239h.
- PUSHAW at 525Fh therefore captures the BP value that entered this block (509Eh or its actual runtime entry), not a value synthesized by the tested memory/PM helpers.
- POPAW at 5289h restores that same BP before the jump to E2C6h and the later 1662h bitmap consumer.
- Consequently BP.13 was already set at the runtime entry into the 509Eh–50A0h block, unless an unexamined asynchronous interrupt path changes the caller's saved context. The normal INT 15h/AH=89h service itself does not change BP.

This does not identify who set BP.13. It establishes a much firmer lower boundary for the search: inspect the actual caller/entry mechanism into the 509Eh region and the code that prepared BP before it.

## 5. Confirmed vs unresolved

### Confirmed
- INT 15h AH=89h dispatches through table entry 933Ah.
- The dispatcher saves/restores BP while using it to index the handler table.
- Handler 933Ah does not write BP; its F66Ah and EEEFh helpers do not write BP.
- F3DBh saves/restores all general registers with PUSHAW/POPAW around INT 10h calls.
- F419h is also PUSHAW/POPAW protected.
- The audited memory helpers 5305h, 534Ch, 5371h, and 53A6h do not write BP.
- The temporary BP=1 on the 51F3h path is restored at 5239h.
- The BP saved at 525Fh is therefore the incoming BP value to this POST/memory-test block.

### Unresolved
- The actual runtime entry into 509Eh/50A0h.
- The caller or earlier firmware code that first sets BP.13.
- Whether the block is entered through a computed far pointer, a table whose values are constructed at runtime, or a stack-crafted continuation.
