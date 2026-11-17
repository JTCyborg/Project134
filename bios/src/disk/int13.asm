; Project134 native INT 13h dispatcher — first reconstruction slice.
;
; Evidence basis:
;   Original dispatcher: F000:A08D/A0A0
;   Selector range:     AH=00h..19h
;   Table:              F000:A0F1..A124 (26 near offsets)
;   Shared error stub:  F000:A18E
;
; This module is deliberately not installed into the IVT yet. The current
; reset.asm is still a bootstrap. Known service slots are routed to a
; temporary failure return until their complete register/flag contracts
; have been reconstructed. Only the unsupported slots below are exact
; reproductions of the observed A18E behavior.
;
; Calling convention: entered by INT 13h; exits with IRET.
; ROM is assembled with ORG 0 and mapped at physical F0000h.

BITS 16

int13_entry:
    push bx                         ; preserve caller BX across table lookup
    cmp ah, 19h
    ja  int13_error_unsupported

    xor bh, bh
    mov bl, ah
    shl bx, 1
    jmp word [cs:bx + int13_dispatch_table]

; Original A18E:
;   MOV AX,0100h
;   MOV [0074h],AH
;   STC
;   RET
; The interrupt wrapper returns with IRET, so the carry is applied to the
; caller's saved FLAGS word. The original BIOS stores status in BDA 0040:0074.
int13_error_unsupported:
    push bp
    mov bp, sp
    push ds

    mov ax, 0040h
    mov ds, ax
    mov byte [0074h], 01h
    mov ax, 0100h
    or word [ss:bp + 8], 0001h

    pop ds
    pop bp
    pop bx
    iret

; Temporary safe fallback for handlers whose complete contracts have not
; yet been ported. This is NOT claimed to match the original implementations.
; It returns the same generic BIOS failure shape but remains explicitly
; separate from the verified unsupported-function target.
int13_pending:
    jmp int13_error_unsupported

; Native little-endian dispatch table, selectors AH=00h..19h.
; Entries marked unsupported map to the verified shared A18E stub behavior.
; Other entries currently point to the explicit pending fallback.
int13_dispatch_table:
    dw int13_pending             ; 00 reset
    dw int13_pending             ; 01 status
    dw int13_pending             ; 02 read sectors
    dw int13_pending             ; 03 write sectors
    dw int13_pending             ; 04 verify sectors
    dw int13_pending             ; 05 format track
    dw int13_error_unsupported  ; 06 unsupported
    dw int13_error_unsupported  ; 07 unsupported
    dw int13_pending             ; 08 get drive parameters
    dw int13_pending             ; 09 initialize drive parameters
    dw int13_pending             ; 0A read long
    dw int13_pending             ; 0B write long
    dw int13_pending             ; 0C seek
    dw int13_pending             ; 0D alternate reset
    dw int13_error_unsupported  ; 0E unsupported
    dw int13_error_unsupported  ; 0F unsupported
    dw int13_pending             ; 10 drive ready
    dw int13_pending             ; 11 recalibrate
    dw int13_error_unsupported  ; 12 unsupported
    dw int13_error_unsupported  ; 13 unsupported
    dw int13_pending             ; 14 controller diagnostic
    dw int13_pending             ; 15 disk type/capacity
    dw int13_error_unsupported  ; 16 unsupported
    dw int13_error_unsupported  ; 17 unsupported
    dw int13_error_unsupported  ; 18 unsupported
    dw int13_pending             ; 19 OEM/extended
