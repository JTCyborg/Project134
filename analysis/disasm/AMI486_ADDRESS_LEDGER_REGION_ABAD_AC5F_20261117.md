# AMI486 address ledger — ATA command wrapper and two command helpers (ABADh–AC5Eh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Entry and dispatch wrapper — ABADh–ABDCh

Direct near-CALL sites: AB45h and AB50h. The caller sets AH=01h before the first call and AH=00h before the second.

The wrapper executes STI and CLD, saves AX/CX/DX/BX/SI/DI/DS/ES, reserves eight local bytes, establishes BP and sets DS=0040h (BIOS Data Area). It selects ABDDh when AH=0 or AC34h when AH is nonzero, then invokes the selected target through CALL AX at AB CCh. LAHF/SAHF preserve the command's returned flags while the wrapper restores the frame and registers.

## 2. ATA IDENTIFY DEVICE helper — ABDDh–AC33h

The helper selects drive/head value A0h when DL=80h, otherwise B0h, and stores it in [BP+7]. It normalizes ES:BX to a paragraph-aligned ES:DI buffer address, calls ATA status helper A655h, writes the selected drive/head value to port 01F6h, and issues command ECh through A73Eh.

It waits through A694h and checks completion through A6DCh. On the accepted status path it reads 0100h words from ATA data port 01F0h using REP INSW. The transfer is enclosed by CLI/STI and CLD. The BIOS Data Area status byte at 0040:0074h is checked before the final return; the error path sets CF and returns at AC33h.

## 3. ATA recalibrate helper — AC34h–AC5Eh

This helper selects the same A0h/B0h drive/head value and stores it in [BP+7]. It calls A655h, writes the drive/head value to port 01F6h, issues ATA command 10h through A73Eh, waits through A694h, and performs completion/status checks through A694h and A6DCh. The short branches at AC43h and AC59h converge on RET at AC5Eh.

This path is selected by the wrapper when AH is nonzero. The exact higher-level reason for choosing recalibrate rather than IDENTIFY is not yet established.

## 4. Disassembly

```asm
ABAD  FB                sti
ABAE  FC                cld
ABAF  50                push ax
ABB0  51                push cx
ABB1  52                push dx
ABB2  53                push bx
ABB3  56                push si
ABB4  57                push di
ABB5  1E                push ds
ABB6  06                push es
ABB7  83 EC 08          sub sp, 08
ABBA  55                push bp
ABBB  8B EC             mov bp, sp
ABBD  B9 40 00          mov cx, 0040
ABC0  8E D9             mov ds, cx
ABC2  0A E4             or ah, ah
ABC4  B8 DD AB          mov ax, ABDD
ABC7  74 03             je ABCC
ABC9  B8 34 AC          mov ax, AC34
ABCC  FF D0             call ax
ABCE  9F                lahf
ABCF  5D                pop bp
ABD0  83 C4 08          add sp, 08
ABD3  9E                sahf
ABD4  07                pop es
ABD5  1F                pop ds
ABD6  5F                pop di
ABD7  5E                pop si
ABD8  5B                pop bx
ABD9  5A                pop dx
ABDA  59                pop cx
ABDB  58                pop ax
ABDC  C3                ret

ABDD  B0 A0             mov al, A0
ABDF  80 FA 80          cmp dl, 80
ABE2  74 02             je ABE6
ABE4  B0 B0             mov al, B0
ABE6  88 46 07          mov [bp+07], al
ABE9  8B C3             mov ax, bx
ABEB  C1 E8 04          shr ax, 04
ABEE  8C C1             mov cx, es
ABF0  03 C1             add ax, cx
ABF2  8E C0             mov es, ax
ABF4  83 E3 0F          and bx, 0F
ABF7  E8 5B FA          call A655
ABFA  72 37             jb AC33
ABFC  8B FB             mov di, bx
ABFE  8C C6             mov si, es
AC00  BA F6 01          mov dx, 01F6
AC03  8A 46 07          mov al, [bp+07]
AC06  EE                out dx, al
AC07  B0 EC             mov al, EC
AC09  E8 32 FB          call A73E
AC0C  E8 85 FA          call A694
AC0F  72 22             jb AC33
AC11  E8 C8 FA          call A6DC
AC14  73 07             jae AC1D
AC16  80 3E 74 00 11    cmp byte ptr [0074], 11
AC1B  75 0D             jne AC2A
AC1D  8E C6             mov es, si
AC1F  B9 00 01          mov cx, 0100
AC22  BA F0 01          mov dx, 01F0
AC25  FA                cli
AC26  FC                cld
AC27  F3 6D             rep insw
AC29  FB                sti
AC2A  8A 26 74 00       mov ah, [0074]
AC2E  0A E4             or ah, ah
AC30  74 01             je AC33
AC32  F9                stc
AC33  C3                ret

AC34  B0 A0             mov al, A0
AC36  80 FA 80          cmp dl, 80
AC39  74 02             je AC3D
AC3B  B0 B0             mov al, B0
AC3D  88 46 07          mov [bp+07], al
AC40  E8 12 FA          call A655
AC43  72 19             jb AC5E
AC45  BA F6 01          mov dx, 01F6
AC48  8A 46 07          mov al, [bp+07]
AC4B  EE                out dx, al
AC4C  B0 10             mov al, 10
AC4E  E8 ED FA          call A73E
AC51  E8 40 FA          call A694
AC54  73 05             jae AC5B
AC56  E8 3B FA          call A694
AC59  72 03             jb AC5E
AC5B  E8 7E FA          call A6DC
AC5E  C3                ret
```

## 5. Corrected AC60h keyboard-table boundary

The AC34h helper's final bytes are AC5Bh–AC5Eh: CALL A6DCh followed by RET. Therefore the keyboard data range starts at AC5Fh, not AC5Bh. AC5Fh is a single 00h prefix byte; the confirmed 160-byte keyboard table begins at AC60h.

The keyboard handler at B031h loads BX=AC60h before calling its mapping helper. The AC60h–ACFFh table contains F0h/FFh markers and scan-code-like groups. The separate AD00h–AE5Fh keyboard table remains distinct pending proof of its layout relationship.

## 6. Generator integration and projected range mask

Add three exact windows:
- ABADh/30h — wrapper through RET at ABDCh
- ABDDh/57h — IDENTIFY DEVICE helper through RET at AC33h
- AC34h/2Bh — recalibrate helper through RET at AC5Eh

Move the AC60h keyboard-data range start from AC5Bh to AC5Fh. The AC00h window remains limited to 5Bh bytes (AC00h–AC5Ah); the new AC34h window covers the adjacent second command helper.

Projected range-mask result:
- Candidate windows: 899
- Data ranges: 248
- Unique code-window bytes: 44,534
- Unique data-range bytes: 20,511
- Code/data overlap: 334 bytes
- Code/data union: 64,711 / 65,536 (98.74%)
- Uncovered intervals: 43
- Pages touched/full: 256 / 256, 218 / 256
- Next largest uncovered interval: 2ED8h–2F23h (76 bytes)

These are exact range-mask projections from the 76-byte newly covered gap and four-byte code/data reclassification. The updated generator must be run before the figures are treated as generated manifest results.
