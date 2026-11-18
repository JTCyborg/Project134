; Project134 — AMI486 BIOS reconstruction
; All executable code is authored as NASM instructions.
; The reference ROM is an analysis/behavior oracle only: never copy its bytes.
; Unimplemented ROM space is filled with FFh.

BITS 16
ORG 0

%ifndef ROM_SIZE
    %define ROM_SIZE 65536
%endif
%if ROM_SIZE != 65536
    %error "AMI486 BIOS image must be exactly 64 KiB"
%endif

rom_start:

; F000:88CE — first POST branch. Not yet reconstructed.
times 0x88CE - ($ - rom_start) db 0xFF
bios_8042_clear_entry:
    ; Pending full translation of ami486_branches.disasm.txt.
    ; This path calls shared helpers at EE94h/EE9Dh and 8DC Fh/8DDCh.

; F000:8A04 — reset continuation.
times 0x8A04 - ($ - rom_start) db 0xFF
bios_reset_cmos_path:
    smsw    ax
    test    al, 0x01
    jz      bios_reset_direct_post
    mov     al, 0x8F
    out     0x70, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x00
    out     0x71, al
    jmp     bios_reset_cmos_cleared
bios_reset_direct_post:
    jmp     bios_cmos_resume
    jmp     bios_post_delay_done

; F000:8A20 — CMOS dispatch helper. Pending complete translation.
times 0x8A20 - ($ - rom_start) db 0xFF
bios_cmos_dispatch:
    ; TODO: translate the disassembly and resolve all shared helper targets.

; F000:D604 — reset-time POST entry.
times 0xD604 - ($ - rom_start) db 0xFF
bios_post_entry:
    cli
    cld
    in      al, 0x64
    test    al, 0x04
    jnz     bios_reset_continuation
    jmp     bios_8042_clear_entry

; F000:D60F — fall-through destination after the 8042 path returns.
bios_post_after_8042:
    jmp     bios_ram_test_entry

; F000:D612 — alternate reset path.
bios_reset_continuation:
    jmp     bios_reset_cmos_path

; F000:D615 — CMOS marker read and dispatch.
bios_cmos_resume:
    mov     al, 0x8F
    out     0x70, al
    jcxz    $+2
    in      al, 0x71
    xor     ah, ah
    mov     si, ax
    mov     al, 0x8F
    jcxz    $+2
    out     0x70, al
    xor     al, al
    jcxz    $+2
    jcxz    $+2
    out     0x71, al
    mov     ax, cs
    mov     ss, ax
    mov     ax, si
    cmp     al, 0x04
    je      bios_cmos_pic_init
    cmp     al, 0x05
    je      bios_cmos_pic_init
    cmp     al, 0x0A
    jbe     bios_cmos_dispatch
    jmp     bios_post_delay_done

bios_cmos_pic_init:
    mov     bx, 0x0870
    nop
    mov     sp, 0xD650
    jmp     0xEEE7

; The original code resumes here from its stack-threaded PIC helper.
times 0xD650 - ($ - rom_start) db 0xFF
bios_cmos_pic_return:
    push    dx
    salc
    jmp     bios_cmos_dispatch

; F000:D6DE — stack/register and RAM test continuation.
times 0xD6DE - ($ - rom_start) db 0xFF
bios_ram_test_entry:
    ; TODO: translate D6DEh onward from ami486_post_entry.disasm.txt.
    ; This includes the stack-threaded segment-register test and RAM test.

; F000:D724 — end of the reset delay.
times 0xD724 - ($ - rom_start) db 0xFF
bios_post_delay_done:
    test    byte [cs:0x8281], 0x40
    jnz     bios_post_after_delay
    smsw    ax
    or      ah, ah
    jz      bios_post_after_delay
    mov     eax, cr0
    or      al, 0x10
    mov     cr0, eax
bios_post_after_delay:
    ; Further POST continuation is not yet reconstructed.

; F000:E05B — reset gateway.
times 0xE05B - ($ - rom_start) db 0xFF
reset_gateway:
    jmp     near bios_post_entry
reset_gateway_end:
%if (reset_gateway_end - reset_gateway) != 3
    %error "Unexpected reset gateway size"
%endif

; FFFF:0000 reset vector -> F000:E05B.
times 0xFFF0 - ($ - rom_start) db 0xFF
bios_reset_vector:
    jmp     0xF000:reset_gateway

times ROM_SIZE - ($ - rom_start) db 0xFF

%if ($ - rom_start) != ROM_SIZE
    %error "Incorrect BIOS ROM size"
%endif
