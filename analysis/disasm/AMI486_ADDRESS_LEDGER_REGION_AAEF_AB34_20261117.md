# AMI486 address ledger — ATA ready-wait epilogue and drive-ready poll helper (AAEFh–AB33h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Boundary and caller relationship

The interval begins with the epilogue at AAEFh–AAF2h of the existing ATA wait routine. A separate helper starts at AAF3h and returns at AB33h. The helper is called directly from AAD8h.

The caller at AAD8h uses the helper's carry result to decide whether the device is ready. On carry set it performs a delay and retries with a CX=4000h loop; after the retry path it returns a status through the AAEFh epilogue.

## 2. AAEFh–AAF2h epilogue

- CMC inverts the carry result.
- POP AX / POP CX restores the caller's saved registers.
- RET completes the surrounding ATA-ready wait routine.

## 3. ATA drive-ready poll helper — AAF3h–AB33h

The helper:
- saves DX/AX/DX/BX;
- reads port 80h and calls delay helper F6B8h, then writes the saved value back to port 80h;
- if the delay helper reports failure, returns through STC at AB30h;
- reads ATA status from port 01F7h and returns carry set when BSY (bit 7) is set;
- selects drive/head A0h when DL=80h, otherwise B0h, and writes it to port 01F6h;
- delays through E93Ch with CX=4;
- reads status from 01F7h and tests DRDY (bit 6);
- returns CF=0 when DRDY is set, otherwise sets CF and returns.

This establishes a hardware ATA-ready poll primitive. The exact status semantics of the helper at F6B8h are not inferred beyond its returned condition being tested at AB07h.

Direct near-CALL reference: AAD8h. The helper also calls F6B8h and E93Ch.

## 4. Disassembly

```asm
AAEF  F5                cmc
AAF0  58                pop ax
AAF1  59                pop cx
AAF2  C3                ret

AAF3  52                push dx
AAF4  50                push ax
AAF5  52                push dx
AAF6  53                push bx
AAF7  BA F4 01          mov dx, 01F4
AAFA  33 DB             xor bx, bx
AAFC  E4 80             in al, 80
AAFE  50                push ax
AAFF  E8 B6 4B          call F6B8
AB02  58                pop ax
AB03  E6 80             out 80, al
AB05  5B                pop bx
AB06  5A                pop dx
AB07  75 27             jne AB30
AB09  8A E2             mov ah, dl
AB0B  BA F7 01          mov dx, 01F7
AB0E  EC                in al, dx
AB0F  A8 80             test al, 80
AB11  75 1D             jne AB30
AB13  B0 A0             mov al, A0
AB15  80 FC 80          cmp ah, 80
AB18  74 02             je AB1C
AB1A  B0 B0             mov al, B0
AB1C  BA F6 01          mov dx, 01F6
AB1F  EE                out dx, al
AB20  BA F7 01          mov dx, 01F7
AB23  51                push cx
AB24  B9 04 00          mov cx, 0004
AB27  E8 12 3E          call E93C
AB2A  59                pop cx
AB2B  EC                in al, dx
AB2C  A8 40             test al, 40
AB2E  75 01             jne AB31
AB30  F9                stc
AB31  58                pop ax
AB32  5A                pop dx
AB33  C3                ret
```

## 5. Generator integration and projected coverage

Add two exact candidate windows: AAEFh/04h and AAF3h/41h. Both are code; no new data range is required.

Projected range-mask result:
- Candidate windows: 903
- Data ranges: 249
- Unique code-window bytes: 44,678
- Unique data-range bytes: 20,512
- Code/data overlap: 334 bytes
- Code/data union: 64,856 / 65,536 (98.96%)
- Uncovered intervals: 41
- Pages touched/full: 256 / 256, 222 / 256
- Next largest uncovered interval: 8E09h–8E4Dh (69 bytes)

These are range-mask projections, not generated manifest results; the updated generator and Capstone listing must be regenerated.
