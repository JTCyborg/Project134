# AMI486 address ledger — Setup load-values confirmation prompt/input handler (5959h–59BFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Boundary and classification

The previous 592Ah candidate window ended at 5969h. A new routine begins at 5959h, immediately after the RET at 5958h, and ends at RET 59BFh. The new window is therefore 5959h–59BFh (67h bytes). The adjacent 59C0h–59C5h pointer table and 59C6h–5A4Bh prompt strings remain data, not instructions.

The new candidate overlaps the existing 592Ah window by 17 bytes (5959h–5969h). Its only new coverage is the previously uncovered interval 596Ah–59BFh (86 bytes).

## 2. Routine behavior

The handler:
- copies the selector byte at E1A3h to E19Fh;
- calls the existing NUL-terminated string-length helper at 592Ah;
- derives a display position and stores the resulting cursor coordinate at E180h;
- uses existing text/cursor helpers at 578Dh, 58D3h, 09C1h and 099Dh;
- initializes AL to 4Eh ('N'), outputs characters through 58EEh and reads input through 591Ah;
- uses 591Ah to normalize lowercase ASCII to uppercase;
- echoes Y/N and continues waiting; ESC (1Bh) or Enter (0Dh) reaches the return path;
- ignores other key values and continues the input loop;
- calls the common UI helper at 0995h before returning at 59BFh.

The Y/N branches are not terminal branches: both re-enter the character-output/input loop. ESC and Enter are the terminal keys in this routine.

## 3. Disassembly

```asm
5959  A0 A3 E1          mov al, [E1A3]
595C  A2 9F E1          mov [E19F], al
595F  53                push bx
5960  E8 C7 FF          call 592A
5963  8B D0             mov dx, ax
5965  D1 E8             shr ax, 1
5967  2D 26 0C          sub ax, 0C26
596A  F7 D8             neg ax
596C  50                push ax
596D  03 D0             add dx, ax
596F  42                inc dx
5970  89 16 80 E1       mov [E180], dx
5974  2D 02 02          sub ax, 0202
5977  81 C2 02 02       add dx, 0202
597B  33 DB             xor bx, bx
597D  E8 0D FE          call 578D
5980  58                pop ax
5981  5B                pop bx
5982  E8 4E FF          call 58D3
5985  A1 80 E1          mov ax, [E180]
5988  E8 36 B0          call 09C1
598B  E8 0F B0          call 099D
598E  B0 4E             mov al, 4E
5990  50                push ax
5991  8B 16 80 E1       mov dx, [E180]
5995  E8 56 FF          call 58EE
5998  E8 7F FF          call 591A
599B  8B D0             mov dx, ax
599D  58                pop ax
599E  83 FA 59          cmp dx, 59
59A1  74 05             je 59A8
59A3  83 FA 4E          cmp dx, 4E
59A6  75 04             jne 59AC
59A8  8A C2             mov al, dl
59AA  EB E4             jmp 5990
59AC  83 FA 1B          cmp dx, 1B
59AF  75 04             jne 59B5
59B1  8A C2             mov al, dl
59B3  EB 05             jmp 59BA
59B5  83 FA 0D          cmp dx, 0D
59B8  75 D6             jne 5990
59BA  50                push ax
59BB  E8 D7 AF          call 0995
59BE  58                pop ax
59BF  C3                ret
```

## 4. Control-flow notes

- 5960h calls the existing 592Ah string-length helper.
- 597Dh calls the existing 578Dh helper.
- 5982h calls the existing 58D3h text renderer.
- 5988h calls 09C1h; 598Bh enters 099Dh.
- 5995h outputs at the cursor through 58EEh.
- 5998h calls the 591Ah keyboard ASCII case-normalization helper.
- 59A1h/59A6h distinguish Y and N; both echo the character and loop to 5990h.
- 59AFh accepts ESC; 59B8h accepts Enter. Both reach 59BAh.
- 59BBh calls 0995h; the routine restores AX and returns at 59BFh.

## 5. Related prompt data

The pointer table at 59C0h–59C5h contains offsets 59C6h, 59E3h and 5A19h. The referenced NUL-terminated strings are:

- 59C6h: `Load Original Values (Y/N) ?`
- 59E3h: `Load BIOS Setup Default Values from ROM Table (Y/N) ?`
- 5A19h: `Load Power-On Default Values from ROM Table (Y/N) ?`

These strings corroborate the Setup load-values prompt context. They remain in the existing data ranges.

## 6. Generator integration and coverage

Added seed 5959h with a 67h-byte limit in generator commit baee67301ab87673ab39e188311e997d8c5b20ae. Keep the existing 592Ah string-length candidate unchanged; the overlap is intentional because 5959h is a distinct entry immediately following the RET at 5958h.

Projected range-mask result (generator execution still pending):
- Candidate windows: 891
- Data ranges: 248
- Unique code-window bytes: 44,287
- Unique data-range bytes: 20,517
- Code/data overlap: 334 bytes
- Code/data union: 64,470 / 65,536 (98.37%)
- Uncovered intervals: 46
- Pages touched/full: 256 / 256, 215 / 256
- Next largest uncovered interval: 72D8h–732Ah (83 bytes)

These are range-mask calculations. The per-window Capstone listing must be regenerated from the updated generator before it can be described as regenerated or verified by execution.
