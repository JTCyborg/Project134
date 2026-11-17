# AMI486 address ledger — register context and decimal output helpers (72D8h–732Ch)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Boundary correction

The prior range mask left 72D8h–732Ah uncovered and classified 732Bh onward as data. The bytes at 732Bh–732Ch are actually the final POP AX / RET of the decimal-output wrapper beginning at 7323h. The correct split is:

- Code: 72D8h–732Ch
- Data: 732Dh–737Fh

The existing data range is shortened by two bytes at its beginning. The code area contains four distinct routines, each ending with RET.

## 2. BP-relative register-context save — 72D8h–72F0h

Stores the caller's register context in a 10h-byte BP-relative frame:

| Frame offset | Saved register |
|---:|---|
| BP-02h | AX |
| BP-04h | BX |
| BP-06h | CX |
| BP-08h | DX |
| BP-0Ah | SI |
| BP-0Ch | DI |
| BP-0Eh | DS |
| BP-10h | ES |

Direct near-CALL sites found by scanning the ROM for relative CALL targets: 6975h, 69D7h, 6C3Fh, 6CECh, 6E34h, 6EA7h, 6F42h, 6F79h, 6FB1h and 71A5h. Several callers visibly establish BP and reserve a 10h-byte local frame before calling this helper.

## 3. BP-relative register-context restore — 72F1h–7309h

Restores AX/BX/CX/DX/SI/DI/DS/ES from the same BP-relative offsets. It does not restore BP, which remains the frame base used by the caller.

Direct near-CALL sites: 69C8h, 6A4Eh, 6C99h, 6D8Ch, 6E6Dh, 6ECBh, 6F70h, 6F9Eh, 6FDEh and 71DDh. This pairing with the save helper confirms the stack-frame context-save/restore role.

## 4. Unsigned decimal output helper — 730Ah–7322h

The helper divides DX:AX by ten, recursively emits the quotient when nonzero, then converts the remainder in DL to an ASCII digit and outputs it using BIOS INT 10h, AH=0Eh. The recursion therefore prints the most significant digit first.

The only direct near-CALL site is 7326h, from the wrapper at 7323h.

## 5. Register-preserving decimal-output wrapper — 7323h–732Ch

Saves AX, BX and DX, calls the decimal output helper at 730Ah, restores DX/BX/AX and returns. Direct callers found in the ROM: 6C75h, 6C96h, 7179h, 719Bh and 71DAh.

This matches the use of helper 7323h by the POST/Setup metric-display paths already mapped around 714Eh–71E3h.

## 6. Disassembly

```asm
72D8  89 46 FE          mov [bp-02h], ax
72DB  89 5E FC          mov [bp-04h], bx
72DE  89 4E FA          mov [bp-06h], cx
72E1  89 56 F8          mov [bp-08h], dx
72E4  89 76 F6          mov [bp-0Ah], si
72E7  89 7E F4          mov [bp-0Ch], di
72EA  8C 5E F2          mov [bp-0Eh], ds
72ED  8C 46 F0          mov [bp-10h], es
72F0  C3                ret

72F1  8B 46 FE          mov ax, [bp-02h]
72F4  8B 5E FC          mov bx, [bp-04h]
72F7  8B 4E FA          mov cx, [bp-06h]
72FA  8B 56 F8          mov dx, [bp-08h]
72FD  8B 76 F6          mov si, [bp-0Ah]
7300  8B 7E F4          mov di, [bp-0Ch]
7303  8E 5E F2          mov ds, [bp-0Eh]
7306  8E 46 F0          mov es, [bp-10h]
7309  C3                ret

730A  BB 0A 00          mov bx, 000Ah
730D  33 D2             xor dx, dx
730F  F7 F3             div bx
7311  0B C0             or ax, ax
7313  74 05             je 731Ah
7315  52                push dx
7316  E8 F4 FF          call 730Dh
7319  5A                pop dx
731A  8A C2             mov al, dl
731C  0C 30             or al, 30h
731E  B4 0E             mov ah, 0Eh
7320  CD 10             int 10h
7322  C3                ret

7323  50                push ax
7324  53                push bx
7325  52                push dx
7326  E8 E1 FF          call 730Ah
7329  5A                pop dx
732A  5B                pop bx
732B  58                pop ax
732C  C3                ret
```

## 7. Generator integration and projected range mask

The generator now has four separate entries with exact limits: 72D8h/19h, 72F1h/19h, 730Ah/19h and 7323h/0Ah. The data range previously beginning at 732Bh now begins at 732Dh.

Projected range-mask result after this boundary correction:
- Candidate windows: 895
- Data ranges: 248
- Unique code-window bytes: 44,372
- Unique data-range bytes: 20,515
- Code/data overlap: 334 bytes
- Code/data union: 64,553 / 65,536 (98.50%)
- Uncovered intervals: 45
- Pages touched/full: 256 / 256, 217 / 256
- Next largest uncovered interval: 83AEh–83FFh (82 bytes)

The range figures are projected from the exact changed intervals; the updated generator has not yet been executed and the full Capstone candidate listing remains pending regeneration.
