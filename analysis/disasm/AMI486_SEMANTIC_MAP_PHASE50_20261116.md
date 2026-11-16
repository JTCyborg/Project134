# AMI486 semantic map — phase 50 (2026-11-16)

## Scope

Followed the alternate POST route from the 8042 SYS-status branch at `D604`, audited BP initialization along the `D74C` route, and resolved the stock indirect dispatch through `CS:[82DA]`. The goal was to determine whether this route supplies BP bit 13 or provides an indirect entry into `8400h`.

## 1. SYS=1 route from D604

At `D604`, BIOS reads port `64h` and tests bit 2 (8042 SYS):

- SYS clear: `D60C -> 88CE`, the previously analyzed real-mode continuation.
- SYS set: `D612 -> 8A04`.

At `8A04`, BIOS executes `SMSW AX; TEST AL,1`:

- If CR0.PE is set, it writes zero to CMOS index `8Fh` and enters the reset-pulse/halt path at `8AD5`.
- If CR0.PE is clear, it jumps to `D615`, which reads CMOS `8Fh`, clears that CMOS byte, and dispatches based on the saved value.

This is a distinct path from the SYS-clear `88CE` path. Its BP state must be analyzed independently.

## 2. BP initialization on the D74C route

The only static transfer to `D74C` is through `8A75`; `8A75` itself is an unconditional jump to `D74C`.

The visible predecessor is:

```asm
D724  test byte ptr cs:[8281],40h
D72A  jne D73B
D72C  smsw ax
D72F  or ah,ah
D731  je D73B
D733  mov eax,cr0
D736  or al,10h
D738  mov cr0,eax
D73B  mov al,03h
D73D  out 80h,al
D73F  mov ax,cs
D741  mov ss,ax
D743  xor bp,bp
D745  mov ds,bp
D747  mov es,bp
D749  jmp 8A75
8A75  jmp D74C
```

Thus BP is explicitly zeroed immediately before the only listed entry to `D74C`.

At `D74C`:

- The code establishes POST checkpoint 04h and sets SS=CS, DS=ES=0000h.
- It tests port `64h` bit 2. If set, `OR BP,1000h` sets BP bit 12.
- It compares BDA word `0040:0472` with `1234h`. Only on equality does `OR BP,8000h` set BP bit 15.
- No instruction on this path sets BP bit 13.

The resulting BP value on this statically reconstructed route is therefore one of `0000h`, `1000h`, `8000h`, or `9000h`, depending on the two tests. This excludes the D74C path as the producer of bit 13.

## 3. Resolve the indirect jump at 8A78

The POST sequence reaches `8A78` from `D774`. The instruction is:

```asm
8A78  mov ax,word ptr cs:[82DA]
8A7C  mov di,8A81
8A7F  jmp ax
```

The ROM bytes at `82DAh` are `AB 19`, so the stock pointer is `19ABh`.

Offset `19ABh` is an intentional alternate entry into the two-byte instruction `FF E7`:

```asm
19AB  jmp di
```

The trampoline therefore resolves exactly:

`8A78 -> 19AB (JMP DI) -> 8A81 -> 8CCD`

At `8A81`, DI is changed to `8A87`, and control is passed to `8CCD`. The stock indirect pointer does **not** target `8400h`. The only static reference to `82DAh` in the linear listing is this read; no in-ROM write to the pointer was found.

This resolves one important indirect dispatch, but does not prove that every dynamic or externally supplied route into `8400h` is impossible.

## 4. Consequences for BP bit 13 and 8400h

### Confirmed

- SYS=1 at `D604` enters `8A04`, not `88CE`.
- The real-mode `D724 -> D743 -> 8A75 -> D74C` route initializes BP to zero before `D74C`.
- `D74C` can set BP bits 12 and 15 only; it does not set bit 13.
- The stock `CS:[82DA]` pointer equals `19ABh`; its trampoline resolves to `8CCD`, not `8400h`.
- The `D74C` route therefore does not explain the inherited `BP.13` tested at `5CF9h`.

### Still unresolved

- The producer or runtime source of BP bit 13 on the path that eventually reaches `DA9F -> 5BF8`.
- Whether `8400h` has a computed entry supplied by a different runtime pointer or external caller.
- The full semantic purpose of the `8CCD` handler reached by the `82DAh` trampoline.

The complete 64-KiB byte decode remains a mechanical listing, not a complete control-flow graph. Alternate instruction boundaries, data tables, and stack-created continuations remain explicit constraints on reachability claims.
