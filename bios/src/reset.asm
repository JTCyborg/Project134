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
; F000:8CCDh — CR0 cache-disable helper and 8042 command/response helper.
times 0x8CCD - ($ - rom_start) db 0xFF
bios_cr0_disable_cache_if_real_mode:
    smsw    ax
    test    al, 0x01
    jnz     bios_indexed_jump_di
    or      ah, ah
    jnz     bios_indexed_jump_di
    mov     eax, cr0
    or      eax, 0x60000000
    mov     cr0, eax
    wbinvd
    xor     ax, ax
bios_indexed_jump_di:
    jmp     di

; The byte at 8CEAh is an alternate/overlapping decode byte; the reachable
; helper entry below is the verified 8CEBh stream.
times 0x8CEB - ($ - rom_start) db 0xFF
bios_8042_wait_and_read:
    loopne  0x8D20
    leave
    jcxz    $+2
bios_8042_wait_input_empty:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_wait_input_empty
    jnz     bios_8042_command_done
    mov     al, ah
    out     0x64, al
    xor     cx, cx
    jcxz    $+2
bios_8042_wait_output_full:
    in      al, 0x64
    test    al, 0x01
    loope   bios_8042_wait_output_full
    in      al, 0x60
bios_8042_command_done:
    ret

; F000:8D09 — ALi indexed-register mode helpers.
times 0x8D09 - ($ - rom_start) db 0xFF
bios_ali_mode_enable:
    mov     ax, 0xC503
    call    0x8DDC
    mov     ax, 0x1818
    call    0x8DCF
    or      al, 0x04
    xchg    ah, al
    call    0x8DDC
    and     ah, 0xFB
    call    0x8DDC
    mov     ax, 0x2323
    call    0x8DCF
    or      al, 0x02
    xchg    ah, al
    call    0x8DDC
    mov     ax, 0x5503
    call    0x8DDC
    mov     cx, 0
    ret

times 0x8D39 - ($ - rom_start) db 0xFF
bios_ali_mode_disable:
    mov     ax, 0xC503
    call    0x8DDC
    mov     ax, 0x2323
    call    0x8DCF
    and     al, 0xFD
    xchg    ah, al
    call    0x8DDC
    mov     ax, 0x5503
    call    0x8DDC
    mov     cx, 0
    ret

times 0x8D56 - ($ - rom_start) db 0xFF
bios_ali_memory_mode:
    mov     ax, 0xC503
    call    0x8DDC
    mov     ax, 0x1818
    call    0x8DCF
    test    al, 0x02
    jnz     bios_ali_memory_mode_done
    mov     di, 0x8D6C
    jmp     0x2686
bios_ali_memory_mode_done:
    mov     di, 0x8D72
    jmp     0x2629
    mov     ax, 0x1818
    call    0x8DCF
    or      al, 0x02
    xchg    ah, al
    call    0x8DDC
    mov     cx, 0xFFFF
    ret

times 0x8D83 - ($ - rom_start) db 0xFF
bios_ali_shadow_mode:
    mov     ax, 0xC503
    mov     di, 0x8D8C
    jmp     short 0x8DFB
    nop
bios_ali_shadow_step_1:
    mov     ax, 0x1919
    mov     di, 0x8D95
    jmp     short 0x8DED
    nop
bios_ali_shadow_step_2:
    or      al, 0x03
    xchg    ah, al
    mov     di, 0x8D9F
    jmp     short 0x8DFB
    nop
bios_ali_shadow_step_3:
    mov     di, 0x8DA5
    jmp     0x2686
bios_ali_shadow_step_4:
    mov     ax, 0x1919
    mov     di, 0x8DAE
    jmp     short 0x8DED
    nop
bios_ali_shadow_step_5:
    and     al, 0xFC
    xchg    ah, al
    mov     di, 0x8DB8
    jmp     short 0x8DFB
    nop
bios_ali_shadow_step_6:
    mov     ax, 0x1818
    mov     di, 0x8DC1
    jmp     short 0x8DED
    nop
bios_ali_shadow_step_7:
    and     al, 0xFD
    xchg    ah, al
    mov     di, 0x8DCB
    jmp     short 0x8DFB
    nop
bios_ali_shadow_return:
    mov     cx, 0xFFFF
    ret

; F000:8DCF / 8DDC — ALi1429 indexed read/write primitives.
times 0x8DCF - ($ - rom_start) db 0xFF
bios_ali_read_index:
    out     0x22, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x23
    jcxz    $+2
    jcxz    $+2
    ret

bios_ali_write_index:
    out     0x22, al
    jcxz    $+2
    jcxz    $+2
    xchg    al, ah
    out     0x23, al
    jcxz    $+2
    jcxz    $+2
    xchg    al, ah
    ret

; F000:8DED — indexed read followed by stack-threaded DI continuation.
bios_ali_read_then_jump:
    out     0x22, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x23
    jcxz    $+2
    jcxz    $+2
    jmp     di

; F000:8DFB — indexed write primitive with register restoration.
bios_ali_write_then_return:
    out     0x22, al
    jcxz    $+2
    jcxz    $+2
    xchg    al, ah
    out     0x23, al
    jcxz    $+2
    jcxz    $+2
    xchg    al, ah
    ret

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

; F000:D6A8 — CMOS[8Fh] indexed near-jump table (11 recovered entries).
; These are semantic 16-bit code offsets, not copied instruction bytes.
times 0xD6A8 - ($ - rom_start) db 0xFF
bios_cmos_8f_dispatch_table:
    dw      0xD724
    dw      0x91D1
    dw      0xF71E
    dw      0x5280
    dw      0xF724
    dw      0xF731
    dw      0x5486
    dw      0x1B5B
    dw      0x8A1D
    dw      0x9206
    dw      0xF737
bios_cmos_8f_dispatch_table_end:
%if (bios_cmos_8f_dispatch_table_end - bios_cmos_8f_dispatch_table) != 22
    %error "CMOS 8Fh dispatch table must contain eleven words"
%endif

; D6BEh — common stack/register test failure path.
bios_stack_test_failure:
    mov     bp, 0x0005
    jmp     0xF4A5

; D6C4h — copy register state through all segment registers, then execute
; the code at SS:SP. This is an intentional JMP-SP trampoline.
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
    jmp     sp

; D6DEh — first SS:SP test stream.
times 0xD6DE - ($ - rom_start) db 0xFF
bios_stack_test_entry:
    mov     al, 0x01
    out     0x80, al
    mov     sp, 0x5555
    cmp     sp, 0x5555
    jnz     bios_stack_test_failure
    mov     sp, 0xAAAA
    cmp     sp, 0xAAAA
    jnz     bios_stack_test_failure
    mov     ax, 0x5555
    mov     sp, 0xD6FC
    jmp     0xD6C4

; D6FCh — continuation reached through the D6C4h JMP SP trampoline.
bios_stack_test_pattern_5555:
    xor     ax, 0x5555
    jnz     bios_stack_test_failure
    mov     ax, 0xAAAA
    mov     sp, 0xD709
    jmp     0xD6C4

; D709h — second pattern check, then CMOS marker and delay.
bios_stack_test_pattern_aaaa:
    xor     ax, 0xAAAA
    jnz     bios_stack_test_failure
    mov     al, 0x8D
    out     0x70, al
    mov     al, 0x02
    out     0x80, al
    mov     al, [cs:0x8284]
    or      al, al
    jz      bios_post_delay_complete
bios_post_delay_loop:
    loop    bios_post_delay_loop
    dec     al
    jnz     bios_post_delay_loop

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
