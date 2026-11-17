; Project134 bootstrap BIOS — independent implementation.
; Provisional 64 KiB flat ROM layout for build-pipeline validation only.
; The final ROM size and mapping must be confirmed against the exact PCem ROM loader.

BITS 16
ORG 0

%ifndef ROM_SIZE
    %define ROM_SIZE 65536
%endif

%if ROM_SIZE != 65536
    %error "Bootstrap currently supports only the provisional 64 KiB ROM layout"
%endif

; PC BIOS reset mapping assumption: ROM occupies F0000h..FFFFFh.
; Place the first instruction at ROM offset E000h => F000:E000.
times 0xE000 - ($ - $$) db 0xFF

bios_entry:
    cli
    cld

    ; Establish a known real-mode stack in conventional RAM.
    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Keep DS/ES pointing at the BIOS segment for future local data.
    mov ax, 0xF000
    mov ds, ax
    mov es, ax

.bootstrap_halt:
    hlt
    jmp .bootstrap_halt

; INT 13h reconstruction slice. It is compiled into the ROM but is not yet
; installed in the IVT: POST/vector installation is still pending.
%include "disk/int13.asm"

; x86 reset vector at physical FFFF0h (offset FFF0h in this 64 KiB image).
times 0xFFF0 - ($ - $$) db 0xFF
    db 0xEA             ; JMP FAR ptr16:16
    dw 0xE000           ; offset
    dw 0xF000           ; segment

times ROM_SIZE - ($ - $$) db 0xFF
