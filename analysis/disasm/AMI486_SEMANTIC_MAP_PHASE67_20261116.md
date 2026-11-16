# AMI486 semantic map — phase 67 (2026-11-16)

## Scope

Continued phase 66 by tracing the two callback call sites that consume the CS-resident slots at 82DEh and 82E2h. This pass used the exact checked-in 64-KiB `ami486.bin` image (blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`) and verified the relative CALL displacements against the raw ROM bytes.

## 1. Callback slot 82E2h: caller at 12E7h

The bytes at 12E7h are:

```asm
12E7  E8 72 09       call 1C5Eh
12EA  FB             sti
12EB  B0 8D          mov al,8Dh
12ED  F6 06 80 82 10 test byte [0080h],10h
12F3  74 20          jz 1315h
```

At 1C5Eh the ROM reads `CS:[82E2h]` and calls the resulting near pointer. The ROM default word at 82E2h is 19AEh; 19AEh contains RET. Thus, on this caller path, the callback returns directly to 12EAh and execution continues with STI and the following POST step marker.

The call is real and statically reachable from its containing routine; the default callback itself remains inert.

## 2. Callback slot 82DEh: caller at 52A1h

The bytes around the second call are:

```asm
5274  2E F6 06 81 82 40  test byte [CS:8281h],40h
527B  74 03             jz 5280h
527D  E9 59 38          jmp 8AD9h
...
529E  B0 57             mov al,57h
52A0  E6 80             out 80h,al
52A2  E8 62 C9          call 1C06h
52A5  B0 58             mov al,58h
52A7  E6 80             out 80h,al
```

The branch at 527Bh means this call site is reached when bit 6 of CS:8281h is clear; when set, execution diverts to 8AD9h. The 1C06h routine reads `CS:[82DEh]` and calls AX. The default slot value is 19ADh, which contains RET. The callback therefore returns to the caller and the POST marker 58h is emitted.

## 3. What the caller trace changes

The two slots are not merely unused pointer-table entries:
- 82E2h is consumed by a real CALL from 12E7h.
- 82DEh is consumed by a real CALL from 52A1h on the branch where CS:8281h bit 6 is clear.
- In the checked-in ROM image both default targets are RET stubs, so neither callback writes BP nor redirects execution into DAxx.
- These are independent call sites in different POST/control paths; they should not be merged into one common caller chain.

The slot defaults and target bytes are corroborated by the raw table:
- 82DEh = 19ADh; 19ADh = C3h (RET).
- 82E2h = 19AEh; 19AEh = C3h (RET).

## 4. Evidence limits

This is static ROM evidence, not a runtime trace. A runtime patch of either slot by an external component remains theoretically possible, but no such writer has been established. The relative-CALL scan is a candidate generator; the two caller sites above were checked against instruction boundaries and their surrounding byte sequences.

This pass does not identify the producer of BP.13 and does not establish an entry into DA5Eh/DA61h.

## Next target

Trace the callers' containing routines further backward and forward, especially the branch into 8AD9h from 527Dh and the POST state controlling CS:8281h bit 6. In parallel, continue the write-provenance audit for the 82D8h–82E6h callback table.
