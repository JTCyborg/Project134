# AMI486 semantic map — phase 45 (2026-11-16)

## Scope and decoding caveat

This phase reconstructs the stack-return path around 5BF8h–5C8Ch and checks whether the apparent D9E0h–DA9Fh sequence is a proven upstream caller. ROM basis: ami486.bin, 64 KiB; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b.

The linear listing is not a control-flow graph. In this region, several routines deliberately set SP and JMP into a helper whose RET consumes bytes from the new stack as a continuation address. Linear instruction boundaries therefore do not describe the executed instruction stream.

## 1. Stack continuation around 5C60h

- 5C60h sets SP=5C66h and jumps to 552Ah.
- 552Ah performs a destructive-pattern/readback memory test and eventually returns.
- The 5C50h path also sets SP=5C56h and jumps to F5A9h; F5A9h–F5BBh ends in RET, which consumes the stack-supplied continuation at 5C56h.
- There is no direct CALL/JMP target to 5C70h in the listing. The stack redirection and RETs are the control-transfer mechanism; 5C70h is not a proven standalone entry.

The bytes at 5C66h onward are therefore unsafe to interpret using the linear decoder's instruction boundaries. The continuation predicate and stack contents must be recovered from the memory-test path, not inferred from sequential disassembly.

## 2. The 5BF8h test has one statically visible incoming branch

The full linear listing has one direct transfer to 5BF8h: DA9Fh, a near JMP.

At 5BF8h the code emits POST code 20h to port 80h, sets SP=5C02h, and jumps to F5A9h. F5A9h toggles port 61h speaker bits and returns through the stack-supplied continuation at 5C02h. The memory probe then initializes DI=0 and SI=1, writes FFFFh words, verifies reads, and reports a memory-test error by setting BP=3 at 5C37h before jumping to F4A5h.

On the successful path, the 5C04h–5C5Ah probe does not initialize BP. BP is tested at 5C58h with OR BP,BP; its sign selects either the 5520h clearing path or the later 552Ah memory test. Thus BP is inherited from an earlier context.

## 3. Why DA9Fh is not yet a proven live caller

The linear bytes immediately preceding the apparent timer setup include D9D9h, a near JMP with displacement 411Fh. In 16-bit IP arithmetic this wraps to 1AFBh, not to an address outside the 64 KiB image.

1AFBh begins a CMOS B3h read path and sets SP=1B04h before jumping to the CMOS read helper. Its stack continuation is at 1B04h, not in the D9E0h region.

Therefore D9E0h–DA9Fh is not reached by ordinary fall-through from D9D9h. The linear listing contains no direct CALL/JMP to D9DCh, D9E0h, or DA9Fh, and no statically visible MOV SP setup targeting D9DCh–DA9Fh. These bytes may be an alternate entry, embedded code, or unreachable residue; execution is not proven.

Inside this unproven block, DA5Ah loads DX=0061h and calls F598h through a stack continuation. F598h polls IN AL,DX and does not modify DX. If the block is independently entered at D9E0h and runs through DA9Fh, DX would still be 0061h at the jump to 5BF8h. Because the entry is unproven, this cannot be promoted to the register provenance at 88D3h.

## 4. BP provenance update

The DAxx block contains DA29h: OR BP,1 on a conditional PIT test path, and DA95h: MOV BP,1 immediately followed by a jump to F4A5h. Neither operation sets BP bit 13. If DA9Fh is entered, BP otherwise remains inherited. The block's live reachability is unresolved.

The 5C04h memory test sets BP=3 only on its error path, followed by a non-returning alarm/beep loop at F4A5h. That value is not the source of the normal 5CF9h bit-13 test.

## 5. Conclusions and unresolved items

Confirmed:
- 5C70h is not a proven standalone entry; this region relies on stack-crafted continuations.
- 5BF8h has one direct incoming transfer in the linear listing, from DA9Fh.
- The 5C04h memory probe does not initialize BP on its successful path.
- The DAxx block's local DX setup would yield DX=0061h, and F598h preserves DX.
- The D9D9h near JMP wraps to 1AFBh; D9E0h–DA9Fh is not reached by sequential execution from that point.

Unresolved:
- Whether D9E0h–DA9Fh has an alternate indirect entry.
- The true upstream BP/DX register contract for the 5BF8h→5Cxx path and 88D3h.
- The origin of BP bit 13.
- The semantic meaning of the special DH=4 continuation.

Do not use DX=0061h as a proven input to the B3h bit-1 writer. It is only a conditional result under an unverified alternate entry into D9E0h.