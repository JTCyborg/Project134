# AMI486 semantic map — phase 66 (2026-11-16)

## Scope

Continued the indirect-dispatch audit around the CS-resident pointer block at 82A0h–82E6h. The goal was to distinguish actual runtime callback slots from nearby literal data and determine whether these slots explain the missing BP.13 / DAxx entry.

## 1. Pointer block at 82A0h–82E6h

The raw words in the saved byte window decode as follows for the relevant tail:

| CS offset | Word | Observed use |
|---|---:|---|
| 82D8h | 19A3h | No direct read site identified in the current reference set |
| 82DAh | 19ABh | Read at 8A78h; indirect transfer |
| 82DCh | 19A5h | No direct read site identified in the current reference set |
| 82DEh | 19ADh | Read at 1C06h; indirect near CALL |
| 82E0h | 19A7h | No direct read site identified in the current reference set |
| 82E2h | 19AEh | Read at 1C5Eh; indirect near CALL |
| 82E4h | 19A9h | No direct read site identified in the current reference set |
| 82E6h | 19AFh | No direct read site identified in the current reference set |

These values are ROM-resident defaults in the inspected image. They are not evidence that all slots are initialized dynamically at POST.

## 2. The 82DAh dispatch is a JMP-DI trampoline

At 8A78h the code performs:

~~~asm
8A78  mov ax,[cs:82DAh]   ; AX = 19ABh in this ROM image
8A7C  mov di,8A81h
8A7F  jmp ax              ; bytes FF E0
~~~

The destination 19ABh contains `FF E7` (JMP DI). Thus the observed stock chain is:

~~~asm
8A78 -> 19AB -> 8A81
~~~

This confirms that 82DAh is a real indirect-dispatch slot, and its default target is a tiny trampoline. It is not a direct dispatch to the 8400h/DAxx code being investigated.

## 3. 82DEh and 82E2h are default no-op callbacks

The two call sites are:

~~~asm
1C06  mov ax,[cs:82DEh]   ; AX = 19ADh
1C0A  call ax             ; FF D0
...
1C5E  mov ax,[cs:82E2h]   ; AX = 19AEh
1C62  call ax             ; FF D0
~~~

The corresponding default targets are:

- 19ADh: `RET`
- 19AEh: `RET`

Therefore both calls are no-op callbacks in the unmodified ROM image. The 1C5Eh callback precedes the chipset/configuration work beginning at 1C64h; the 1C06h callback is a separate earlier hook. Their default targets cannot set BP, change the stack, or transfer control into DAxx.

This also explains why a linear decode around 19ABh–19AFh looks misleading: these are overlapping entry points into a compact trampoline/RET-stub byte sequence, not a normal sequence of unrelated instructions.

## 4. What this does and does not establish

Confirmed:
- 82DAh contains 19ABh in the target ROM image; 19ABh jumps through DI.
- The live 8A78h dispatch therefore reaches the caller-supplied continuation at 8A81h.
- 82DEh and 82E2h point to RET stubs 19ADh and 19AEh, so the two observed indirect CALLs are inert by default.
- These three observed pointer slots do not provide a static route to DA5Eh, DA61h, 509Eh, or 8400h.

Not established:
- Whether any of the pointer words are patched at runtime through a write form not covered by the earlier simple immediate/store scan.
- Whether an external option ROM, chipset hook, or pre-POST path modifies the callback slots.
- The first producer of BP.13 and the runtime entry into DAxx.

## 5. Next analysis target

Audit every write form capable of modifying the CS-resident slots (including segment-relative stores, string writes, and block copies), then inspect the 1C06h/1C5Eh callers and their predecessors for setup of the callback environment. Keep the BP.13 and DAxx hypotheses open until a real writer or runtime trace is found.
