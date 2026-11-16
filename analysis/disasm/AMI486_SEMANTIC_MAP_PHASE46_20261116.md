# AMI486 semantic map — phase 46 (2026-11-16)

## Scope

Rechecked every direct control-transfer reference into D8xx–DAxx, the two direct entries at D90Dh, and the D8EAh path from 86D8h. ROM basis: ami486.bin, 64 KiB; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b.

## 1. Confirmed external entries

The full linear listing contains these direct transfers into the D8/D9 region:
- 8408h -> D90Dh
- 84C8h -> D90Dh
- 86D8h -> D8EAh

The first two are genuine branch instructions, not inferred fall-through. At 8400h, the code tests CS:8280 bit 6; if clear, it jumps to D90Dh. The 84C8h transfer is the terminal path of the 8485h–84C6h loop: it is reached after the scan pointer SI reaches or passes CS:82C2h.

At 86D8h, AX is loaded from DX and execution jumps to D8EAh. MOV preserves flags, so D8EAh's conditional branch consumes the flags established immediately before this handoff (not flags created by MOV AX,DX). The caller-side path includes OR SP,SP at 86D4h and MOV AX,DX at 86D6h.

## 2. What D8EAh does to BP

From D8EAh the branch tree can set only low BP flags:
- D8ECh path: OR BP,20h
- D8F3h path: OR BP,10h
- D8DCh path, reached through D8E7h -> 868Bh -> ... -> 86D8h -> D8EAh: OR BP,08h

These are BP bits 5, 4, and 3. None sets bit 13 (mask 2000h). D8FAh then masks AL with FEh, swaps AL/AH, sets SP= D904h, and jumps to CMOS write helper EE9Dh. This is a stack-crafted CMOS update path, not an origin for BP bit 13.

## 3. D90Dh is a live CMOS/POST path, but it does not continue into DAxx

Both 8408h and 84C8h enter at D90Dh. It emits POST 10h, then performs CMOS accesses using stack-crafted continuations and the helpers EE94h/EE9Dh. It proceeds through the CMOS indexes 8Bh, 8Ch, 8Ah, 8Eh and related update operations.

At D951h it sets SP= D958h and jumps to F659h. The helper returns into the stack continuation at D958h, whose first opcode is POP DX. This is a real register load from the crafted stack, not preservation of an upstream DX value. The following code checks keyboard/controller response (IN AL,60h; compare with 52h), then sends command ADh to port64h on the alternate branch.

The live D90Dh path continues through D9D9h, whose near JMP displacement wraps to 1AFBh in 16-bit IP arithmetic. Thus it does not sequentially enter D9E0h–DA9Fh. The D90Dh entry proves the earlier blanket claim that no external D9xx code is reachable was too broad, but it does not make the DAxx timer block live.

## 4. Register provenance consequences

- BP on the D90Dh path is not initialized by the two visible entry branches 8408h/84C8h. No BP bit-13 assignment occurs in the D90Dh sequence. The exact upstream BP value remains dependent on the indirect/outer caller.
- DX at D958h is explicitly loaded by POP DX from bytes beginning at D958h after the stack-redirection return. Therefore the value is determined by the stack continuation bytes, not by an incoming caller's DX.
- The D90Dh route does not establish DX=0061h at 88D3h; it is a different path and exits to 1AFBh before the DAxx code.
- The D8EAh route can set BP bits 3–5 only; it is not the source of BP bit 13.

## 5. Corrections and unresolved items

Correction to phase 45: its statement that no external direct entry exists anywhere in D8xx–DAxx was too broad. Phase 46 establishes direct entries at 8408h/84C8h to D90Dh and at 86D8h to D8EAh. Phase 45's narrower conclusion remains valid: DA9Fh's block is not reached sequentially from D9D9h, and no direct entry to DA9Fh/D9E0h was found.

Still unresolved:
- The indirect caller/register setup that reaches 8400h and 84C8h, including incoming BP state.
- Any independent indirect entry into D9E0h–DA9Fh.
- The source of BP bit 13 tested at 5CF9h.
- The DH=4 stack continuation at 88EEh–8921h and the true DX register contract at 88D3h.

## 6. Phase 46 conclusion

The newly proven D90Dh path is a CMOS/POST routine with explicit stack-based DX restoration. It is not the missing upstream source for the 5CF9h bit-13 decision. Continue by resolving the indirect entry into 8400h and tracing the 88D3h DH/DL inputs independently.