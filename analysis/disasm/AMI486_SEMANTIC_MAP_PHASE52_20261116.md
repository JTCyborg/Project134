# AMI486 semantic map — phase 52 (2026-11-16)

## Scope

Traced the CMOS 8Fh selector targets that restore the saved caller context, especially selectors 3 and 6, and corrected the reachability interpretation of the D6A2 jump table.

## 1. Important correction to phase 51: D6A2 is not reached by all selectors 0..10

D637 handles selector values 04h and 05h specially: both branch to D646, build a stack continuation at D650, and jump to EEE7. They do not fall through to D6A2 on this path.

Values 00h..03h and 06h..0Ah branch to D652 -> 8A20. From there the code tests selectors 05h, 09h, 0Ah and chipset flags; the ordinary route reaches D690, where the indexed jump at D6A2 is executed. Selector 05h is already diverted by D637, so it is not a D6A2 selector on the normal path. Selectors 09h and 0Ah may take the alternate D66D route depending on the tested conditions.

Therefore the table bytes remain correctly decoded, but the earlier statement that selectors 0..10 are all valid reachable table entries was too broad. Selector 4 and 5 are definitely diverted before the table; selector 9 and 10 have a conditional alternate path. See the actual branch gates in D637–D66D and 8A20–8A72.

## 2. Selector 3: 5280 restores the saved general-register image

The selector-3 table entry targets 5280h:

```asm
5280  mov ax,[0067]
5283  mov sp,ax
5285  mov al,54h
5287  out 80h,al
5289  popaw
528A  mov al,55h
528C  out 80h,al
528E  call 8AD2
5291  call F66E
```

At 5260 the preceding setup executes `PUSHAW`, then stores the resulting SP in BDA word 0067h. Thus 5280 resets SP to the saved PUSHAW frame and POPAW restores DI, SI, BP, the saved SP slot, BX, DX, CX and AX.

This is a concrete BP restoration point: the BP value used after selector 3 is not created by the 5280 routine. It is restored from the saved register frame at the stack address recorded in 0040:0067. This may preserve a caller's BP value, but the actual saved word depends on the context that reached the save at 5260.

After POPAW, the path disables A20 through 8AD2/F66E and continues through the recovery/return code at 52C4 or 5296 onward. The POPAW operation itself does not set BP.13; it restores the saved word.

## 3. Selector 6: 5486 also restores a saved register image

The selector-6 target begins:

```asm
5486  mov ax,[0067]
5489  mov sp,ax
548B  call 5572
548E  mov al,0Dh
5490  call F53C
5493  popaw
5494  pushaw
5495  mov ax,bx
5497  add ax,bp
...
54D2  mov ah,89h
54D4  int 15h
...
54E0  popaw
54E1  ret
```

The frame at 0040:0067 is used again. The first POPAW at 5493 restores BP from that saved frame; PUSHaw at 5494 immediately saves the working register state again. On successful INT 15h/AH=89h, the handler later POPAWs at 54E0 and returns.

The selector-6 path therefore also transports BP through a saved register frame. It is a candidate for carrying a pre-existing BP.13 value, but it does not originate that bit in the shown routine.

## 4. Selector 1 and other targets

- Selector 1 -> 91D1 restores SS:SP from BDA 0069:0067, calls the A20-disable helper, then joins the protected-mode/A20 cleanup continuation. It does not directly restore BP with POPAW at 91D1; the common return path at 91A4 does POPAW from the saved caller frame.
- Selector 2 -> F71E sets BP=7 and enters the fatal POST error path F4A5. This is an explicit BP write, but it sets bit 2 only, not bit 13.
- Selector 4/5 are diverted at D637 to EEE7 stack continuation, not the D6A2 table.
- Selector 7 -> 1B5B, a near jump to D724.
- Selector 8 -> 8A1D, a near jump to D724.
- Selector 9 -> 9206, which restores SS:SP from BDA and calls A20-disable helpers before joining 9214.
- Selector 10 -> F737, an indirect far jump through the saved vector at physical 0067h.

## 5. Consequences for BP.13

This phase establishes two real BP-preserving paths:
- selector 3 restores BP from the saved PUSHAW frame at 0040:0067;
- selector 6 restores BP from the same saved frame at 0040:0067.

Neither path creates BP.13 in its own code. The next step is to identify the code that populated the PUSHAW frame at 5260, and to trace which earlier path can arrive there with BP bit 13 already set.

The only direct BP write found among the inspected selector targets is F71E: `MOV BP,7`, which cannot explain bit 13. The producer remains unresolved.

## 6. Confirmed vs unresolved

### Confirmed
- Selectors 04h and 05h are diverted at D637 before the D6A2 table.
- Selectors 09h and 0Ah can be diverted by the D655/D66D branch conditions.
- Selector 3 restores the register frame with POPAW at 5289.
- Selector 6 restores the register frame with POPAW at 5493 and again at 54E0.
- Both saved-frame paths can preserve BP.13 if it was present in the saved BP word.
- Selector 2's F71E handler sets BP=7 and enters the fatal path.

### Unresolved
- Which caller reaches the PUSHAW save at 5260 with BP.13 set.
- Whether the CMOS 8Fh value is externally seeded, retained from a prior POST phase, or written by another earlier stage.
- Any other dynamic entry into 8400h.

The linear listing is not a complete CFG. Stack-crafted continuations, external interrupt entry, and alternate instruction boundaries remain relevant.


## Post-audit correction — direct D906h to 8400h entry (2026-11-17)

The earlier unresolved statement about any non-table dynamic entry into 8400h is now resolved. D8FEh sets SP=D904h and jumps to EE9Dh; the stack word at D904h is D906h, so the helper returns to D906h. The aligned stream is `MOV AL,0Fh; OUT 80h,AL; JMP 8400h` (E9 F3 AAh at D90Ah resolves to 8400h). This is a direct near-JMP entry and is independent of the D6A2h table. The earlier phase-51 finding remains correct: none of the eleven D6A2h table words equals 8400h.

At 8400h, CS:8280h bit 40h gates a CMOS 8Eh path. It reads CMOS 8Eh, executes `AND BP,FFC7h` (clears BP bits 3–5 and preserves bit 13), clears CMOS 8Eh–FFh, then restores the 32-byte block at CMOS 8Eh–ADh from the ROM table at 820Eh and merges further table-driven fields. This path does not create BP.13; its producer remains unresolved. The aligned stack-return slots 8414h, 842Ah, 8444h, 8460h, 847Eh, 849Eh and 84BCh are data, with continuations 8416h, 842Ch, 8446h, 8462h, 8480h, 84A0h and 84BEh. See `AMI486_ADDRESS_LEDGER_REGION_D655_E3FF_20261117.md`.
