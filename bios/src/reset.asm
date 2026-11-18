; Project134 — independent AMI486 BIOS reconstruction.
; Stage 0: address-accurate reset gateway and verified early POST dispatcher.
; This image is intentionally marked INCOMPLETE: destinations outside this
; implemented window are not yet reconstructed, so it is not PCem-bootable.

BITS 16
ORG 0

%ifndef ROM_SIZE
    %define ROM_SIZE 65536
%endif

%if ROM_SIZE != 65536
    %error "AMI486 reconstruction currently requires a 64 KiB ROM"
%endif

; The reference ROM reset vector is FFFF:0000 -> F000:E05B.
; PCem maps this 64 KiB image into the F0000h..FFFFFh BIOS window.

; ---------------------------------------------------------------------------
; Verified early POST entry at ROM offset D604h (CS=F000h).
; Source: ami486_post_entry.disasm.txt, byte-backed disassembly.
; Preserve the original instruction stream and exact near-branch destinations.
; ---------------------------------------------------------------------------
times 0xD604 - ($ - $$) db 0xFF
bios_post_entry:
    db 0xFA                         ; CLI
    db 0xFC                         ; CLD
    db 0xE4, 0x64                   ; IN AL,64h
    db 0xA8, 0x04                   ; TEST AL,04h
    db 0x75, 0x06                   ; JNZ D612h
    db 0xE9, 0xBF, 0xB2             ; JMP 88CEh
    db 0xE9, 0xCC, 0x00             ; JMP D6DEh (alternate entry)
    db 0xE9, 0xEF, 0xB3             ; JMP 8A04h
    db 0xB0, 0x8F                   ; MOV AL,8Fh
    db 0xE6, 0x70                   ; OUT 70h,AL
    db 0xE3, 0x00                   ; JCXZ $+2
    db 0xE3, 0x00                   ; JCXZ $+2
    db 0xE4, 0x71                   ; IN AL,71h
    db 0xB4, 0x00                   ; MOV AH,00h
    db 0x8B, 0xF0                   ; MOV SI,AX
    db 0xB0, 0x8F                   ; MOV AL,8Fh
    db 0xE3, 0x00
    db 0xE3, 0x00
    db 0xE6, 0x70                   ; OUT 70h,AL
    db 0xB0, 0x00
    db 0xE3, 0x00
    db 0xE3, 0x00
    db 0xE6, 0x71                   ; OUT 71h,AL
    db 0x8C, 0xC8                   ; MOV AX,CS
    db 0x8E, 0xD0                   ; MOV SS,AX
    db 0x8B, 0xC6                   ; MOV AX,SI
    db 0x3C, 0x04                   ; CMP AL,04h
    db 0x74, 0x0B
    db 0x3C, 0x05
    db 0x74, 0x07
    db 0x3C, 0x0A
    db 0x76, 0x0F
    db 0xE9, 0xDE, 0x00             ; JMP D724h
    db 0xBB, 0x70, 0x08             ; MOV BX,0870h
    db 0x90
    db 0xBC, 0x50, 0xD6             ; MOV SP,D650h
    db 0xE9, 0x97, 0x18             ; JMP EEE7h
    db 0x52
    db 0xD6
    db 0xE9, 0xCB, 0xB3             ; JMP 8A20h
    db 0x74, 0x39
    db 0x2E, 0xF6, 0x06, 0x81, 0x82, 0x40 ; TEST BYTE [CS:8281h],40h
    db 0x75, 0x31
    db 0x8B, 0xC6
    db 0x3C, 0x05
    db 0x74, 0x08
    db 0x3C, 0x09
    db 0x74, 0x04
    db 0x3C, 0x0A
    db 0x75, 0x23
    db 0x66, 0xC1, 0xC8, 0x10
    db 0x8B, 0xC8
    db 0x0F, 0x01, 0xE0             ; SMSW AX
    db 0x0A, 0xE4
    db 0x0F, 0x20, 0xC0             ; MOV EAX,CR0
    db 0x74, 0x04
    db 0x0C, 0x10
    db 0xEB, 0x06
    db 0x66, 0x25, 0xFF, 0xFF, 0xFF, 0x9F
    db 0x0F, 0x22, 0xC0             ; MOV CR0,EAX
    db 0x8B, 0xC1
    db 0x66, 0xC1, 0xC8, 0x10
    db 0xB8, 0x40, 0x00             ; MOV AX,0040h
    db 0x8E, 0xD8                   ; MOV DS,AX
    db 0xB0, 0x00
    db 0x8E, 0xC0                   ; MOV ES,AX
    db 0xB0, 0x30
    db 0x8E, 0xD0                   ; MOV SS,AX
    db 0xBC, 0x00, 0x01             ; MOV SP,0100h
    db 0xD1, 0xE6
    db 0x2E, 0xFF, 0xA4, 0xA8, 0xD6 ; JMP WORD [CS:SI-2958h]

; ---------------------------------------------------------------------------
; Reset gateway. The first instruction at E05Bh is a near JMP to D604h.
; Bytes E9 A6 F5 are verified from the target ROM disassembly.
; ---------------------------------------------------------------------------
times 0xE05B - ($ - $$) db 0xFF
bios_reset_gateway:
    db 0xE9, 0xA6, 0xF5             ; JMP D604h

; x86 reset vector at physical FFFF0h: far jump to F000:E05B.
times 0xFFF0 - ($ - $$) db 0xFF
    db 0xEA
    dw 0xE05B
    dw 0xF000

times ROM_SIZE - ($ - $$) db 0xFF
