# AMI486 semantic map — phase 55 (2026-11-16)

## Scope

Continue tracing the BP value entering the 5C04h memory test. Reconstruct the concrete predecessor of 5C04h and inspect the DAxx timing path that branches to it.

## 1. Concrete stack-crafted path into 5C04h

The bytes and stack operations establish this continuation:

```asm
DA9F  jmp 5BF8
5BF8  mov al,20h
5BFA  out 80h,al
5BFC  mov sp,5C02h
5BFF  jmp F5A9
5C02  db 04h,5Ch       ; RET target = 5C04h
5C04  xor di,di
```

F5A9 is the existing port-61 helper whose RET consumes the word at 5C02h. Therefore the transfer into the memory-test body at 5C04h is not a conventional CALL and does not push a return address: the caller explicitly installs SP=5C02h, and the helper's RET resumes at 5C04h.

This confirms the mechanics of the 5BF8h -> F5A9h -> 5C04h path. It does not, by itself, prove that DA9Fh is entered during every POST run.

## 2. DA9Fh is the success exit of a PIT/port-61 timing check

The code immediately preceding DA9Fh is a coherent timing test:

- DA9Bh emits POST marker 1Bh.
- DA9Fh jumps to the memory-test continuation.
- DA61h first calls F598h with DX=0061h and a crafted return at DA64h.
- DA68h–DA88h samples port 61h transitions and derives an absolute count delta in CX.
- DA8Bh compares the result with 0Ah.
- If the count is below 0Ah, it branches to DA9Bh and then DA9Fh.
- If the count is at least 0Ah, it tests CS:[8280h].7. When set, it sets BP=1 at DA95h and enters fatal alarm F4A5h; otherwise it also proceeds to DA9Bh/DA9Fh.
- An earlier check at DA46h can bypass the timing loop and jump directly to DA9Bh when CS:[8280h].7 is clear or CS:[8285h] is nonzero.

The only BP write in the successful DA61h–DA9Fh timing path is absent: the BP=1 assignment at DA95h belongs exclusively to the fatal-alarm branch. DA29h can OR BP with 1 on a PIT test mismatch; it only affects bit 0.

Thus this DAxx path does not establish BP.13. It preserves whatever higher BP bits were present on entry.

## 3. Entry into the DAxx timing block remains unresolved

No direct near CALL/JMP to DA61h or DA9Fh was found in the linear listing. The observed transfer into 5BF8h is from DA9Fh, and the internal branches prove how DA9Fh can be reached once execution is in the DAxx block, but the external entry into DA61h/DA46h is still unknown.

Do not treat the adjacent linear bytes at D9DCh–D9E0h as the predecessor: D9D9h is a near jump whose 16-bit IP arithmetic wraps to 1AFBh, as established in earlier phases. A linear listing boundary is not a control-flow edge.

## 4. BP preservation through the later POST path

The 5DBDh sequence is confirmed to preserve BP:

```asm
5DBB  push ds
5DBC  push es
5DBD  push bp
5DBE  call 1B5F
5DC1  pop bp
5DC2  pop es
5DC3  pop ds
```

1B5Fh is a one-byte RET stub. The CALL returns immediately and the following POP BP restores the exact value saved at 5DBDh. It cannot be the source of BP.13.

Likewise, the previously traced memory-test and keyboard-controller code from 5C04h through 5D07h does not set bit 13. The only BP assignment at 5C37h is on the fatal memory-test error path.

## 5. Additional audit of BP writers

The executable-looking early POST region contains explicit BP flag accumulations at 113Bh (bit 9), 1141h (bit 10), 117Fh (bit 8), 11A1h/11BCh (bit 11), and 145Eh (bit 6). None sets bit 13.

At 12D3h–12D4h, POP BP is followed by AND BP,C000h, which discards bits 0–13 on that particular path. This is not a source for BP.13.

The linear decode also contains BP arithmetic and POP BP sites in mixed code/data regions. Without verified control-flow ownership and stack provenance, those sites cannot be assigned as producers for the 5Cxx POST path.

## 6. Confirmed vs unresolved

### Confirmed
- DA9Fh -> 5BF8h -> F5A9h -> RET to 5C04h is a real stack-crafted continuation when the DAxx path reaches DA9Fh.
- The return word at 5C02h is 5C04h.
- The DAxx timing path sets BP=1 only on the fatal-alarm branch at DA95h; DA29h only ORs bit 0.
- The successful DAxx path does not set BP.13.
- 5DBDh/1B5Fh/5DC1h saves and restores BP unchanged.
- The audited 11xx POST flag producers set bits 6, 8, 9, 10 and 11, not bit 13.
- 12D3h–12D4h clears BP bits 0–13 after restoring BP on that separate path.

### Unresolved
- The runtime entry into the DAxx timing block.
- The value of BP at that entry, and therefore at 5C04h.
- Whether BP.13 is supplied by an earlier caller's register state or an untraced stack restore.
- Whether any apparently BP-writing instructions in the low-offset mixed code/data region belong to reachable BIOS code.

The current evidence narrows the BP.13 origin to before the DAxx timing path; no instruction in the verified DAxx -> 5C04h -> 5CF9h path creates it.
