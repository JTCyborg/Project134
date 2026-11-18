; Project134 — AMI486 BIOS reconstruction
; NASM-only executable implementation. Reference ROM is analysis-only.
; FFh fill is reserved for regions not yet reconstructed.

BITS 16
ORG 0
%ifndef ROM_SIZE
    %define ROM_SIZE 65536
%endif
%if ROM_SIZE != 65536
    %error "AMI486 BIOS image must be exactly 64 KiB"
%endif
rom_start:

; ---------------------------------------------------------------------------
; F000:88CE — 8042 clear / reset branch.
; This region is deliberately left unimplemented until its stack-threaded
; continuations and overlapping entry points are fully mapped.
times 0x88CE - ($ - rom_start) db 0xFF
bios_8042_clear_entry:
    ; TODO: full translation of 88CEh–8A03h.

; ---------------------------------------------------------------------------
; F000:8A04 — reset-mode dispatch.
times 0x8A04 - ($ - rom_start) db 0xFF
bios_reset_cmos_path:
    smsw    ax
    test    al, 0x01
    jz      bios_reset_to_cmos_read
    mov     al, 0x8F
    out     0x70, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x00
    out     0x71, al
    jmp     bios_reset_keyboard_wait
bios_reset_to_cmos_read:
    jmp     bios_cmos_read
bios_reset_to_post_delay:
    jmp     bios_post_delay_complete

; ---------------------------------------------------------------------------
; F000:8A20 — CMOS marker dispatcher.
times 0x8A20 - ($ - rom_start) db 0xFF
bios_cmos_dispatch:
    mov     ax, si
    cmp     al, 0x05
    je      bios_cmos_pic_dispatch
    cmp     al, 0x09
    je      bios_cmos_pic_dispatch
    cmp     al, 0x0A
    jne     bios_cmos_post_55
bios_cmos_pic_dispatch:
    mov     al, 0xB3
    mov     sp, 0x8A36
    jmp     0xEE94
bios_cmos_pic_return:
    cmp     [bp+si+0x0CA8], cl
    jz      bios_cmos_post_55
    mov     dl, al
    ror     eax, 16
    mov     bx, ax
    mov     di, bios_cmos_mode_table
    jmp     0x8CCD
bios_cmos_mode_table:
    mov     di, 0x8E62
    mov     cx, 0x000A
    test    dl, 0x04
    jnz     bios_cmos_mode_selected
    mov     di, 0x8E7A
    mov     cx, 0x0002
bios_cmos_mode_selected:
    mov     ax, [cs:di]
    inc     di
    inc     di
    mov     sp, 0x8A66
    jmp     0x8DDC
bios_cmos_mode_return:
    push    word 0xE28A
    int1
    mov     ax, bx
    ror     eax, 16
bios_cmos_post_55:
    or      al, 0xFF
    jmp     0xD655
    jmp     0xD74C

; ---------------------------------------------------------------------------
; F000:8AD5 — reset keyboard-controller wait and CPU reset request.
times 0x8AD5 - ($ - rom_start) db 0xFF
bios_reset_keyboard_wait:
    cli
    cli
    xor     cx, cx
    jcxz    $+2
bios_keyboard_wait_busy:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_keyboard_wait_busy
    mov     al, 0xFE
    out     0x64, al
bios_keyboard_reset_halt:
    hlt
    jmp     bios_keyboard_reset_halt

; ---------------------------------------------------------------------------
; F000:D604 — reset-time POST entry and CMOS marker dispatch.
times 0xD604 - ($ - rom_start) db 0xFF
bios_post_entry:
    cli
    cld
    in      al, 0x64
    test    al, 0x04
    jnz     bios_reset_continuation
    jmp     bios_8042_clear_entry
bios_post_ram_test:
    jmp     bios_ram_test_entry
bios_reset_continuation:
    jmp     bios_reset_cmos_path

; F000:D615 — exact CMOS marker read, clear and dispatch sequence.
bios_cmos_read:
    mov     al, 0x8F
    out     0x70, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x71
    mov     ah, 0
    mov     si, ax
    mov     al, 0x8F
    jcxz    $+2
    out     0x70, al
    mov     al, 0
    jcxz    $+2
    jcxz    $+2
    out     0x71, al
    mov     ax, cs
    mov     ss, ax
    mov     ax, si
    cmp     al, 0x04
    je      bios_pic_init
    cmp     al, 0x05
    je      bios_pic_init
    cmp     al, 0x0A
    jna     bios_cmos_dispatch_entry
    jmp     bios_post_delay_complete

bios_pic_init:
    mov     bx, 0x0870
    nop
    mov     sp, 0xD650
    jmp     0xEEE7
bios_pic_return:
    push    dx
    salc
bios_cmos_dispatch_entry:
    jmp     bios_cmos_dispatch

; F000:D655 — CMOS marker-dependent CR0 setup and dispatch.
bios_cmos_post:
    jz      bios_post_delay_setup
    test    byte [cs:0x8281], 0x40
    jnz     bios_post_delay_setup
    mov     ax, si
    cmp     al, 0x05
    je      bios_cr0_adjust
    cmp     al, 0x09
    je      bios_cr0_adjust
    cmp     al, 0x0A
    jnz     bios_post_delay_setup
bios_cr0_adjust:
    ror     eax, 16
    mov     cx, ax
    smsw    ax
    or      ah, ah
    mov     eax, cr0
    jz      bios_cr0_clear_cache
    or      al, 0x10
    jmp     bios_cr0_write
bios_cr0_clear_cache:
    and     eax, 0x9FFFFFFF
bios_cr0_write:
    mov     cr0, eax
    mov     ax, cx
    ror     eax, 16
bios_post_delay_setup:
    mov     ax, 0x0040
    mov     ds, ax
    mov     al, 0
    mov     es, ax
    mov     al, 0x30
    mov     ss, ax
    mov     sp, 0x0100
    shl     si, 1
    jmp     word [cs:si-0x2958]

; D6A8h–D6C0h is a CMOS-indexed near-jump table. Its entries are data and
; remain pending semantic reconstruction; do not decode as linear code.
times 0xD6C1 - ($ - rom_start) db 0xFF
bios_post_table_continuation:
    jmp     0xF4A5

; Alternate register/segment test continuation at D6C4h.
bios_segment_test_setup:
    mov     bx, ax
    mov     cx, bx
    mov     dx, cx
    mov     si, dx
    mov     di, si
    mov     bp, di
    mov     es, bp
    mov     ax, es
    mov     ds, ax
    mov     ax, ds
    mov     ss, ax

; F000:D6DE — destructive memory/register test is not yet translated.
times 0xD6DE - ($ - rom_start) db 0xFF
bios_ram_test_entry:
    ; TODO: reconstruct overlapping D6DEh–D723h entry streams.

; F000:D724 — exact delay completion and POST checkpoint 03h.
times 0xD724 - ($ - rom_start) db 0xFF
bios_post_delay_complete:
    test    byte [cs:0x8281], 0x40
    jnz     bios_post_checkpoint_03
    smsw    ax
    or      ah, ah
    jz      bios_post_checkpoint_03
    mov     eax, cr0
    or      al, 0x10
    mov     cr0, eax
bios_post_checkpoint_03:
    mov     al, 0x03
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    xor     bp, bp
    mov     ds, bp
    mov     es, bp
    jmp     0x8A75

; F000:D74C — POST checkpoint 04h and 8042/reset-state dispatch.
bios_post_checkpoint_04:
    mov     al, 0x04
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    xor     ax, ax
    mov     ds, ax
    mov     es, ax
    in      al, 0x64
    and     al, 0x04
    jz      bios_post_checkpoint_05
    or      bp, 0x1000
    cmp     word [0x0472], 0x1234
    jnz     bios_post_checkpoint_05
    or      bp, 0x8000
bios_post_checkpoint_05:
    mov     al, 0x05
    out     0x80, al
    jmp     0x8A78

; F000:E05B — reset gateway.
times 0xE05B - ($ - rom_start) db 0xFF
reset_gateway:
    jmp     near bios_post_entry
reset_gateway_end:
%if (reset_gateway_end - reset_gateway) != 3
    %error "Unexpected reset gateway size"
%endif

; ---------------------------------------------------------------------------
; F000:EE94 — CMOS indexed read helper.
times 0xEE94 - ($ - rom_start) db 0xFF
bios_cmos_read_index:
    out     0x70, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x71
    ret

; F000:EE9D — CMOS indexed write helper.
bios_cmos_write_index:
    out     0x70, al
    xchg    al, ah
    jcxz    $+2
    jcxz    $+2
    out     0x71, al
    xchg    al, ah
    ret

; F000:EEE7 — 8259 PIC initialization.
times 0xEEE7 - ($ - rom_start) db 0xFF
bios_pic_initialize:
    mov     al, 0
    out     0xF1, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x11
    out     0xA0, al
    jcxz    $+2
    jcxz    $+2
    out     0x20, al
    jcxz    $+2
    jcxz    $+2
    mov     al, bl
    out     0xA1, al
    jcxz    $+2
    jcxz    $+2
    mov     al, bh
    out     0x21, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x02
    out     0xA1, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x04
    out     0x21, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x01
    out     0xA1, al
    jcxz    $+2
    jcxz    $+2
    out     0x21, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0xFF
    out     0xA1, al
    jcxz    $+2
    jcxz    $+2
    out     0x21, al
    ret

; FFFF:0000 reset vector -> F000:E05B.
times 0xFFF0 - ($ - rom_start) db 0xFF
bios_reset_vector:
    jmp     0xF000:reset_gateway

times ROM_SIZE - ($ - rom_start) db 0xFF
%if ($ - rom_start) != ROM_SIZE
    %error "Incorrect BIOS ROM size"
%endif
