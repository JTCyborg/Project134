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

; Encode a 16-bit near jump to an absolute offset in the current CS.
; NASM's numeric JMP operand is a displacement, not an absolute IP.
%macro JMP_ABS 1
    ; NASM treats a numeric near-JMP operand as the absolute target offset
    ; and calculates the signed relative displacement itself.
    jmp near %1
%endmacro

; F000:19AB–19AF — stock callback trampolines used by the POST hook slots.
times 0x19AB - ($ - rom_start) db 0xFF
bios_callback_jmp_di:
    jmp     di
bios_callback_ret_19ad:
    ret
bios_callback_ret_19ae:
    ret
bios_callback_ret_19af:
    ret

; F000:1AF8 — POST continuation trampoline into the D82Fh 8042 sequence.
times 0x1AF8 - ($ - rom_start) db 0xFF
bios_post_8042_continuation:
    JMP_ABS 0xD82F

; ---------------------------------------------------------------------------
; F000:1AFB — CMOS B3h profile selection and PIT/speaker initialization.
times 0x1AFB - ($ - rom_start) db 0xFF
bios_cmos_b3_profile_entry:
    mov     al, 0xB3
    nop
    mov     sp, 0x1B04
    JMP_ABS 0xEE94

times 0x1B04 - ($ - rom_start) db 0xFF
bios_cmos_b3_profile_return:
    dw      0x1B06
bios_cmos_b3_profile_continue:
    test    al, 0x0C
    jz      near bios_speaker_pit_init
    mov     si, 0x8E4E
    mov     cx, 0x8E62
    test    al, 0x04
    jnz     near bios_cmos_profile_table_loop
    mov     si, 0x8E76
    mov     cx, 0x8E7A
bios_cmos_profile_table_loop:
    sub     cx, si
    shr     cx, 1
bios_cmos_profile_table_write:
    cs lodsw
    mov     sp, 0x1B2A
    JMP_ABS 0x8DDC

times 0x1B2A - ($ - rom_start) db 0xFF
bios_cmos_profile_write_return:
    dw      0x1B2C
bios_cmos_profile_write_continue:
    loop    bios_cmos_profile_table_write

bios_speaker_pit_init:
    mov     al, 0xFC
    out     0x61, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x00
    out     0x8F, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x54
    out     0x43, al
    jcxz    $+2
    jcxz    $+2
    mov     al, [cs:0x8286]
    out     0x41, al
    jcxz    $+2
    jcxz    $+2
    mov     cx, 0x0400
    xor     di, di
bios_speaker_buffer_clear:
    stosb
    loop    bios_speaker_buffer_clear
    JMP_ABS 0x208D

bios_post_early_reentry:
    JMP_ABS 0xD724
bios_callback_ret_1b5e:
    ret
bios_callback_ret_1b5f:
    ret

; F000:2065 — reset-entry trampoline and protected-mode GDT.
; The descriptor and GDT are reconstructed as NASM data declarations.
times 0x2065 - ($ - rom_start) db 0xFF
bios_reset_entry_trampoline:
    JMP_ABS 0xE05B

; F000:2068 — 16-bit LGDT pseudo-descriptor.
bios_pm_gdt_descriptor:
    dw      0x0017
    ; Low 24 bits are F2070h; retain the original reserved high byte 93h.
    dd      0x930F2070

times 0x2070 - ($ - rom_start) db 0x00
bios_pm_gdt:
    dq      0x0000000000000000
    ; Selector 0008h: flat writable data segment, 4-GiB granularity.
    dw      0xFFFF, 0x0000
    db      0x00, 0x93, 0x8F, 0x00
    ; Selector 0010h: base-zero writable data segment, 64-KiB limit.
    dw      0xFFFF, 0x0000
    db      0x00, 0x93, 0x00, 0x00
bios_pm_gdt_end:
%if (bios_pm_gdt_end - bios_pm_gdt) != 24
    %error "Protected-mode GDT must contain three descriptors"
%endif

; F000:2088 — five-byte parameter area; semantics remain unresolved.
    db      0x01, 0x04, 0x02, 0x10, 0x40

; F000:208D — 21-record ALi1429 profile table walker.
times 0x208D - ($ - rom_start) db 0xFF
bios_ali_profile_apply:
    mov     ax, 0xC503
    mov     sp, 0x2096
    JMP_ABS 0x8DDC

times 0x2096 - ($ - rom_start) db 0xFF
bios_ali_profile_select_return:
    dw      0x2098
bios_ali_profile_select_continue:
    mov     si, 0x8750
    mov     cx, 0x87A4
    sub     cx, 0x8750
    shr     cx, 2
bios_ali_profile_record_loop:
    cs lodsw
    sub     al, 0x30
    mov     bl, al
    cmp     al, 0x26
    jne     bios_ali_profile_record_write
    dec     cx
    add     si, 2
    jmp     short bios_ali_profile_record_loop

bios_ali_profile_record_write:
    cs lodsw
    mov     al, bl
    nop
    mov     sp, 0x20C2
    JMP_ABS 0x8DDC

times 0x20C2 - ($ - rom_start) db 0xFF
bios_ali_profile_write_return:
    dw      0x20C4
bios_ali_profile_write_continue:
    loop    bios_ali_profile_record_loop
    mov     sp, 0x20CC
    jmp     bios_8042_a20_enable

times 0x20CC - ($ - rom_start) db 0xFF
bios_ali_profile_a20_return:
    dw      0x20CE
bios_ali_profile_a20_continue:
    mov     bx, 0x0800
    nop
    mov     sp, 0x20D8
    JMP_ABS 0xEEEF

times 0x20D8 - ($ - rom_start) db 0xFF
bios_ali_profile_eeef_return:
    dw      0x20DA
bios_ali_profile_pm_setup:
    mov     eax, cr0
    or      al, 0x01
    mov     cr0, eax
    cli
    lgdt    [cs:0x2068]
    jmp     short $+2
    mov     ax, 0x0008
    mov     es, ax
    mov     ax, 0x4410
    nop
    mov     sp, 0x20FA
    JMP_ABS 0x8DDC

times 0x20FA - ($ - rom_start) db 0xFF
bios_ali_profile_write_pm_return:
    dw      0x20FC

; F000:8280 — recovered original BIOS configuration bytes.
; These fields are read by POST code at 8280h..8286h.
times 0x8280 - ($ - rom_start) db 0xFF
    db      0x2F, 0x00, 0xE7, 0x03, 0x00, 0x00, 0x12, 0x00

; F000:82D0 — original POST callback vector table.
; CS:82DA is the active POST hook and must resolve to the stock JMP-DI
; trampoline at F000:19AB. The surrounding entries are also consumed by
; the POST/CMOS dispatch paths.
times 0x82D0 - ($ - rom_start) db 0xFF
    dw      0x19A3, 0x0000, 0x19A3, 0x0000
    dw      0x19A3, 0x19AB, 0x19A5, 0x19AD
    dw      0x19A7, 0x19AE, 0x19A9, 0x19AF

; F000:8300 — CPU/cache profile selector and CMOS 8Eh update.
; This region is transcribed from the original instruction stream. Alternate
; but equivalent MOV/XOR/OR encodings are kept byte-exact where NASM canonical
; encoding would otherwise change the ROM checksum.
times 0x8300 - ($ - rom_start) db 0x00
bios_cpu_profile_wrapper:
    push    bx
    call    bios_cpu_profile_selector
    pop     bx
    ret

bios_cpu_profile_selector:
    mov     bx, 0xB7D0
    db      0x0A, 0xC0                 ; or al, al
    jz      short bios_cpu_profile_cmos_update
    db      0x32, 0xE4                 ; xor ah, ah
    mov     bx, 0xB55D
    sub     bx, 0xB508
    db      0x3B, 0xC3                 ; cmp ax, bx
    mov     bx, 0xB7D0
    jc      short bios_cpu_profile_record
    mov     bx, 0xB55D
    sub     bx, 0xB508
    db      0x2B, 0xC3                 ; sub ax, bx

bios_cpu_profile_walk:
    mov     bx, [cs:0x82C6]
    db      0x0A, 0xC0                 ; or al, al
    jz      short bios_cpu_profile_cmos_update
bios_cpu_profile_record:
    mov     ah, [cs:bx+0x1E]
    add     bl, [cs:bx+0x1F]
    adc     bh, 0
    add     bx, 0x20
    test    ah, 0x80
    jz      short bios_cpu_profile_next
    inc     bx
bios_cpu_profile_zero_list:
    inc     bx
    cmp     word [cs:bx-2], 0
    jnz     short bios_cpu_profile_zero_list
bios_cpu_profile_next:
    dec     al
    jnz     short bios_cpu_profile_record

bios_cpu_profile_cmos_update:
    mov     al, 0x8E
    out     0x70, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x71
    db      0x8A, 0xE0                 ; mov ah, al
    mov     al, [cs:bx+0x1C]
    mov     bl, [cs:bx+0x1D]
    test    ah, 0xC0
    jnz     short bios_cpu_profile_cmos_mask
    or      al, 0x80
    out     0x70, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x71
    jmp     short bios_cpu_profile_resolve_shift_setup

bios_cpu_profile_cmos_mask:
    and     al, 0x7F

bios_cpu_profile_cmos_resolve:
    db      0x8A, 0xE3                 ; mov ah, bl
    mov     bx, 0x873C
    cmp     al, [cs:0x8888]
    jbe     short bios_cpu_profile_resolve_scan
    mov     bx, [cs:0x82C0]
bios_cpu_profile_resolve_scan:
    cmp     byte [cs:bx], al
    jz      short bios_cpu_profile_resolve_found
    add     bx, 4
    jmp     short bios_cpu_profile_resolve_scan
bios_cpu_profile_resolve_found:
    mov     al, [cs:bx+3]
    db      0x8A, 0xDC                 ; mov bl, ah
bios_cpu_profile_resolve_shift_setup:
    mov     bh, 0x08
    mov     ah, 0x00
bios_cpu_profile_resolve_shift:
    rol     bl, 1
    jnc     short bios_cpu_profile_resolve_rotate_al
    rol     ax, 1
    jmp     short bios_cpu_profile_resolve_decrement
bios_cpu_profile_resolve_rotate_al:
    rol     al, 1
bios_cpu_profile_resolve_decrement:
    dec     bh
    jnz     short bios_cpu_profile_resolve_shift
    db      0x8A, 0xC4                 ; mov al, ah
    db      0x0A, 0xC0                 ; or al, al
    ret

; F000:83AE — descriptor selector returning the selected profile bytes in AX.
bios_cpu_profile_descriptor:
    mov     bx, 0xB7D0
    db      0x0A, 0xC0                 ; or al, al
    jz      short bios_cpu_profile_descriptor_return
    db      0x32, 0xE4                 ; xor ah, ah
    mov     bx, 0xB55D
    sub     bx, 0xB508
    db      0x3B, 0xC3                 ; cmp ax, bx
    mov     bx, 0xB7D0
    jc      short bios_cpu_profile_descriptor_record
    mov     bx, 0xB55D
    sub     bx, 0xB508
    db      0x2B, 0xC3                 ; sub ax, bx
    mov     bx, [cs:0x82C6]
    db      0x0A, 0xC0                 ; or al, al
    jz      short bios_cpu_profile_descriptor_return
bios_cpu_profile_descriptor_record:
    mov     ah, [cs:bx+0x1E]
    add     bl, [cs:bx+0x1F]
    adc     bh, 0
    add     bx, 0x20
    test    ah, 0x80
    jz      short bios_cpu_profile_descriptor_next
    inc     bx
bios_cpu_profile_descriptor_zero_list:
    inc     bx
    cmp     word [cs:bx-2], 0
    jnz     short bios_cpu_profile_descriptor_zero_list
bios_cpu_profile_descriptor_next:
    dec     al
    jnz     short bios_cpu_profile_descriptor_record
bios_cpu_profile_descriptor_return:
    mov     al, [cs:bx+0x1C]
    mov     ah, [cs:bx+0x1D]
    ret

; F000:8400 — CMOS 8Eh extended-register clear/restore path.
times 0x8400 - ($ - rom_start) db 0xFF
bios_cmos_8e_extended_entry:
    test    byte [cs:0x8280], 0x40
    jnz     short bios_cmos_8e_read
    JMP_ABS 0xD90D

bios_cmos_8e_read:
    mov     al, 0x8E
    nop
    mov     sp, 0x8414
    JMP_ABS 0xEE94

times 0x8414 - ($ - rom_start) db 0xFF
bios_cmos_8e_initial_read_return:
    dw      0x8416
bios_cmos_8e_initial_read_continue:
    test    al, 0xC0
    jz      short bios_cmos_8e_extended_entry+8
    and     bp, 0xFFC7
    mov     al, 0x8E
    mov     cx, 0x0072
    xor     ah, ah
bios_cmos_8e_clear_iteration:
    mov     sp, 0x842A
    JMP_ABS 0xEE9D

times 0x842A - ($ - rom_start) db 0xFF
bios_cmos_8e_clear_return:
    dw      0x842C
bios_cmos_8e_clear_continue:
    inc     al
    loop    bios_cmos_8e_clear_iteration

; The loop's first iteration enters the helper body at 8424h.
times 0x8430 - ($ - rom_start) db 0xFF
bios_cmos_8e_restore_setup:
    mov     al, 0x8E
    mov     cx, 0x0032
    mov     si, 0x820E
bios_cmos_8e_restore_loop:
    mov     ah, al
    cs lodsb
    xchg    ah, al
    mov     sp, 0x8444
    JMP_ABS 0xEE9D

times 0x8444 - ($ - rom_start) db 0xFF
bios_cmos_8e_restore_return:
    dw      0x8446
bios_cmos_8e_restore_continue:
    inc     al
    loop    bios_cmos_8e_restore_loop

bios_cmos_8e_rom_table_setup:
    mov     cx, [cs:0x8886]
    jcxz    bios_cmos_8e_descriptor_setup
    mov     si, 0x873C
bios_cmos_8e_rom_table_loop:
    mov     al, [cs:si]
    or      al, 0x80
    nop
    mov     sp, 0x8460
    JMP_ABS 0xEE94

times 0x8460 - ($ - rom_start) db 0xFF
bios_cmos_8e_rom_table_read_return:
    dw      0x8462
bios_cmos_8e_rom_table_read_continue:
    mov     ah, [cs:si+2]
    mov     dl, [cs:si+1]
    and     ah, dl
    not     dl
    and     al, dl
    or      ah, al
    mov     al, [cs:si]
    or      al, 0x80
    nop
    mov     sp, 0x847E
    JMP_ABS 0xEE94

times 0x847E - ($ - rom_start) db 0xFF
bios_cmos_8e_rom_table_write_return:
    dw      0x8480
bios_cmos_8e_rom_table_write_continue:
    add     si, 0x04
    loop    bios_cmos_8e_rom_table_loop

bios_cmos_8e_descriptor_setup:
    mov     si, [cs:0x82C0]
    cmp     si, [cs:0x82C2]
    jc      short bios_cmos_8e_descriptor_loop
    jmp     short bios_cmos_8e_finish

bios_cmos_8e_descriptor_loop:
    mov     al, [cs:si]
    or      al, 0x80
    mov     sp, 0x849E
    JMP_ABS 0xEE94

times 0x849E - ($ - rom_start) db 0xFF
bios_cmos_8e_descriptor_read_return:
    dw      0x84A0
bios_cmos_8e_descriptor_read_continue:
    mov     ah, [cs:si+2]
    mov     dl, [cs:si+1]
    and     ah, dl
    not     dl
    and     al, dl
    or      ah, al
    mov     al, [cs:si]
    or      al, 0x80
    nop
    mov     sp, 0x84BC
    JMP_ABS 0xEE9D

times 0x84BC - ($ - rom_start) db 0xFF
bios_cmos_8e_descriptor_write_return:
    dw      0x84BE
bios_cmos_8e_descriptor_write_continue:
    add     si, 0x04
    cmp     si, [cs:0x82C2]
    jc      short bios_cmos_8e_descriptor_loop
bios_cmos_8e_finish:
    JMP_ABS 0xD90D

; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; F000:88CE — 8042 clear / reset branch.
; This region is deliberately left unimplemented until its stack-threaded
; continuations and overlapping entry points are fully mapped.
times 0x88CE - ($ - rom_start) db 0xFF
bios_8042_clear_entry:
    mov     cx, 0x0100
bios_8042_delay:
    loop    bios_8042_delay
    mov     ax, cs
    mov     ss, ax
    smsw    ax
    test    al, 0x01
    jnz     short bios_8042_reset_reentry
    or      ah, ah
    jnz     short bios_8042_set_ah_zero
    cmp     dh, 0x04
    jnz     short bios_8042_set_ah_zero
    nop
    mov     sp, 0x88EE
    jmp     short bios_8042_arithmetic_probe
    nop

; The CMOS helper RET consumes this inline word and resumes at 88F0h.
times 0x88EE - ($ - rom_start) db 0xFF
bios_8042_probe_return:
    dw      0x88F0

; This is an intentional overlapping entry: RET above lands at 88F0h,
; inside the linear LOCK/MOV decode beginning at 88EEh.
bios_8042_probe_result:
    jnz     short bios_8042_alternate_cmos
    mov     di, 0x88F8
    jmp     short bios_ali_probe_start
    nop
bios_8042_alternate_test:
    jmp     short bios_8042_cmos_read
bios_8042_alternate_cmos:
    and     dl, 0x30
    cmp     dl, 0x30
    mov     ah, 0x02
    jz      short bios_8042_cmos_read
bios_8042_set_ah_zero:
    mov     ah, 0x00
bios_8042_cmos_read:
    mov     al, 0xB3
    mov     sp, 0x890E
    JMP_ABS 0xEE94

; EE94h returns to 8910h through this semantic stack word.
times 0x890E - ($ - rom_start) db 0xFF
bios_8042_cmos_read_return:
    dw      0x8910
bios_8042_cmos_read_continue:
    and     al, 0xF1
    or      ah, al
    mov     al, 0xB3
    mov     sp, 0x891C
    JMP_ABS 0xEE9D

; EE9Dh returns to 891Eh; that continuation restarts POST at D60Fh.
times 0x891C - ($ - rom_start) db 0xFF
bios_8042_cmos_write_return:
    dw      0x891E
bios_8042_reset_reentry:
    JMP_ABS 0xD60F

; The crafted stack at 88EEh returns here after the arithmetic/flags probe.
bios_8042_arithmetic_probe:
    xor     ax, ax
    sahf
    mov     ax, 0x0005
    mov     bx, 0x0002
    div     bl
    lahf
    cmp     ah, 0x02
    ret

; ALi C2h/C3h indexed-register probe. Each helper returns through an inline
; word (DW) to the aligned continuation immediately following that word.
bios_ali_probe_start:
    xor     cl, cl
    mov     ax, 0xC2C2
    mov     sp, 0x893C
    JMP_ABS 0x8DCF

times 0x893C - ($ - rom_start) db 0xFF
bios_ali_read_c2_return:
    dw      0x893E
bios_ali_read_c2_continue:
    mov     bl, al
    or      al, 0x04
    xchg    ah, al
    mov     sp, 0x894A
    JMP_ABS 0x8DDC

times 0x894A - ($ - rom_start) db 0xFF
bios_ali_write_c2_return:
    dw      0x894C
bios_ali_write_c2_continue:
    mov     sp, 0x8952
    JMP_ABS 0x8DCF

times 0x8952 - ($ - rom_start) db 0xFF
bios_ali_read_c3_return:
    dw      0x8954
bios_ali_read_c3_continue:
    test    al, 0x04
    jz      short bios_ali_c2_set_flag
    mov     ah, bl
    and     ah, 0xFB
    mov     al, 0xC2
    nop
    mov     sp, 0x8966
    JMP_ABS 0x8DDC

times 0x8966 - ($ - rom_start) db 0xFF
bios_ali_write_c2_second_return:
    dw      0x8968
bios_ali_write_c2_second_continue:
    mov     sp, 0x896E
    JMP_ABS 0x8DDC

times 0x896E - ($ - rom_start) db 0xFF
bios_ali_read_c2_second_return:
    dw      0x8970
bios_ali_read_c2_second_continue:
    test    al, 0x04
    jz      short bios_ali_c2_common_write
bios_ali_c2_set_flag:
    or      cl, 0x02
bios_ali_c2_common_write:
    mov     ah, bl
    mov     al, 0xC2
    nop
    mov     sp, 0x8982
    JMP_ABS 0x8DDC

times 0x8982 - ($ - rom_start) db 0xFF
bios_ali_write_c3_return:
    dw      0x8984
bios_ali_write_c3_continue:
    mov     ax, 0xC3C3
    nop
    mov     sp, 0x898E
    JMP_ABS 0x8DCF

times 0x898E - ($ - rom_start) db 0xFF
bios_ali_read_c3_second_return:
    dw      0x8990
bios_ali_read_c3_second_continue:
    mov     bl, al
    or      al, 0x02
    xchg    ah, al
    mov     sp, 0x89A4
    JMP_ABS 0x8DCF

times 0x89A4 - ($ - rom_start) db 0xFF
bios_ali_read_c3_third_return:
    dw      0x89A6
bios_ali_read_c3_third_continue:
    test    al, 0x02
    jz      short 0x89C6
    mov     ah, bl
    and     ah, 0xFB
    mov     al, 0xC3
    nop
    mov     sp, 0x89B8
    JMP_ABS 0x8DDC

times 0x89B8 - ($ - rom_start) db 0xFF
bios_ali_write_c3_second_return:
    dw      0x89BA
bios_ali_write_c3_second_continue:
    mov     sp, 0x89C0
    JMP_ABS 0x8DCF

times 0x89C0 - ($ - rom_start) db 0xFF
bios_ali_read_c3_fourth_return:
    dw      0x89C2
bios_ali_read_c3_fourth_continue:
    test    al, 0x02
    jz      short bios_ali_c3_fourth_no_bit1
    or      cl, 0x01
bios_ali_c3_fourth_no_bit1:
    mov     ah, bl
    mov     al, 0xC3
    nop
    mov     sp, 0x89D4
    JMP_ABS 0x8DDC

times 0x89D4 - ($ - rom_start) db 0xFF
bios_ali_write_c3_third_return:
    dw      0x89D6
bios_ali_write_c3_third_continue:
    mov     ah, 0x08
    cmp     cl, 0x01
    jz      short bios_ali_dispatch_di
    mov     ah, 0x04
    cmp     cl, 0x03
    jz      short bios_ali_dispatch_di
    mov     al, 0xFE
    mov     sp, 0x89EC
    JMP_ABS 0x8DCF

times 0x89EC - ($ - rom_start) db 0xFF
bios_ali_read_final_return:
    dw      0x89EE
bios_ali_read_final_continue:
    mov     ah, 0x04
    cmp     al, 0x05
    jbe     short bios_ali_dispatch_di
    mov     ah, 0x06
    cmp     al, 0x07
    jbe     short bios_ali_dispatch_di
    mov     ah, 0x0A
    test    al, 0x01
    jnz     short bios_ali_dispatch_di
    mov     ah, 0x08
bios_ali_dispatch_di:
    jmp     di

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
    JMP_ABS 0xEE94
bios_cmos_pic_return:
    cmp     [bp+si+0x0CA8], cl
    jz      bios_cmos_post_55
    mov     dl, al
    ror     eax, 16
    mov     bx, ax
    mov     di, bios_cmos_mode_table
    JMP_ABS 0x8CCD
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
    JMP_ABS 0x8DDC
bios_cmos_mode_return:
    push    word 0xE28A
    int1
    mov     ax, bx
    ror     eax, 16
bios_cmos_post_55:
    or      al, 0xFF
    JMP_ABS 0xD655
    JMP_ABS 0xD74C

; ---------------------------------------------------------------------------
; F000:8A78 — dynamic POST hook and stack-threaded ALi setup continuation.
times 0x8A78 - ($ - rom_start) db 0xFF
bios_post_dynamic_hook:
    mov     ax, [cs:0x82DA]
    mov     di, 0x8A81
    jmp     ax

bios_post_dynamic_hook_return:
    mov     di, 0x8A87
    JMP_ABS 0x8CCD
bios_post_dynamic_hook_nop:
    nop
    mov     sp, 0x8A8E
    JMP_ABS 0x8D83

times 0x8A8E - ($ - rom_start) db 0xFF
bios_post_ali_mode_return:
    dw      0x8A90
bios_post_ali_mode_continue:
    mov     ax, 0xB3B3
    nop
    mov     sp, 0x8A9A
    JMP_ABS 0xEE94

times 0x8A9A - ($ - rom_start) db 0xFF
bios_post_cmos_b3_read_return:
    dw      0x8A9C
bios_post_cmos_b3_read_continue:
    and     al, 0xFE
    xchg    ah, al
    mov     sp, 0x8AA6
    JMP_ABS 0xEE9D

times 0x8AA6 - ($ - rom_start) db 0xFF
bios_post_cmos_b3_write_return:
    dw      0x8AA8
bios_post_cmos_b3_write_continue:
    mov     ax, 0xC503
    nop
    mov     sp, 0x8AB2
    JMP_ABS 0x8DDC

times 0x8AB2 - ($ - rom_start) db 0xFF
bios_post_ali_1313_write_return:
    dw      0x8AB4
bios_post_ali_1313_write_continue:
    mov     ax, 0x1313
    nop
    mov     sp, 0x8ABE
    JMP_ABS 0x8DCF

times 0x8ABE - ($ - rom_start) db 0xFF
bios_post_ali_1313_read_return:
    dw      0x8AC0
bios_post_ali_1313_read_continue:
    and     al, 0x3F
    xchg    ah, al
    mov     sp, 0x8ACA
    JMP_ABS 0x8DDC

times 0x8ACA - ($ - rom_start) db 0xFF
bios_post_ali_1313_final_return:
    dw      0x8ACC
bios_post_ali_1313_final_continue:
    JMP_ABS 0xD777

; Independent 8042 command trampolines in the same ROM window.
bios_8042_enable_trampoline:
    JMP_ABS 0xF66A
bios_8042_disable_trampoline:
    JMP_ABS 0xF66E

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
bios_8042_wait_input_empty_8ceb:
    jcxz    $+2
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_wait_input_empty_8ceb
    jnz     bios_8042_command_done
    mov     al, ah
    out     0x64, al
    xor     cx, cx
bios_8042_wait_output_full:
    jcxz    $+2
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
    jnz     short bios_ali_memory_mode_return
    mov     di, 0x8D6C
    JMP_ABS 0x2686
bios_ali_memory_mode_retry:
    mov     di, 0x8D72
    JMP_ABS 0x2629
bios_ali_memory_mode_apply:
    mov     ax, 0x1818
    call    0x8DCF
    or      al, 0x02
    xchg    ah, al
    call    0x8DDC
bios_ali_memory_mode_return:
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
    JMP_ABS 0x2686
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
    JMP_ABS 0xEEE7
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
    JMP_ABS 0xF4A5

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
bios_ram_test_entry:
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
    jmp     short 0xD6C4

; D6FCh — continuation reached through the D6C4h JMP SP trampoline.
bios_stack_test_pattern_5555:
    xor     ax, 0x5555
    jnz     bios_stack_test_failure
    mov     ax, 0xAAAA
    mov     sp, 0xD709
    jmp     short 0xD6C4

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
    JMP_ABS 0x8A75

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
    JMP_ABS 0x8A78

; ---------------------------------------------------------------------------
; F000:D777 — memory checksum, 8042 drain and keyboard-controller POST.
times 0xD777 - ($ - rom_start) db 0xFF
bios_post_memory_checksum:
    mov     al, 0x06
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    xor     ax, ax
    mov     ds, ax
    mov     es, ax
    xor     bx, bx
    mov     cx, 0x8000
    xor     si, si
bios_post_checksum_loop:
    cs lodsw
    add     bx, ax
    loop    bios_post_checksum_loop
    jz      bios_post_8042_drain
    mov     bp, 0x0009
    JMP_ABS 0xF4A5

bios_post_8042_drain:
    xor     cx, cx
bios_post_8042_status:
    in      al, 0x64
    mov     ah, al
    test    al, 0x01
    jz      bios_post_8042_test_input
    in      al, 0x60
bios_post_8042_test_input:
    test    ah, 0x02
    loopne  bios_post_8042_status
    mov     al, 0x07
    out     0x80, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0xAA
    xchg    bx, bx
    xchg    bx, bx
    xchg    bx, bx
    xchg    bx, bx
    xchg    bx, bx
    xchg    bx, bx
    xchg    bx, bx
    nop
    jmp     short bios_post_8042_command_aa

bios_post_8042_command_aa:
    out     0x64, al
    in      al, 0x64
    xor     di, di
    test    al, 0x01
    jz      bios_post_8042_response_wait
    dec     di
bios_post_8042_response_wait:
    nop
    mov     sp, 0xD7D8
    JMP_ABS 0xF659

times 0xD7D8 - ($ - rom_start) db 0xFF
bios_post_8042_wait_aa_return:
    dw      0xD7DA
bios_post_8042_wait_aa_continue:
    mov     al, 0x08
    out     0x80, al
    mov     sp, 0xD7E4
    JMP_ABS 0xF60F

times 0xD7E4 - ($ - rom_start) db 0xFF
bios_post_8042_read_response_return:
    dw      0xD7E6
bios_post_8042_read_response_continue:
    cmp     al, 0x55
    jz      bios_post_8042_response_ok
    test    byte [cs:0x8280], 0x80
    jz      bios_post_8042_response_ok
    mov     bp, 0x0006
    JMP_ABS 0xF4A5

bios_post_8042_response_ok:
    or      di, di
    jz      bios_post_keyboard_init_done
    mov     al, 0xA1
    out     0x64, al
    mov     sp, 0xD806
    JMP_ABS 0xF659

times 0xD806 - ($ - rom_start) db 0xFF
bios_post_8042_a1_return:
    dw      0xD808
bios_post_8042_a1_continue:
    xor     cx, cx
bios_post_8042_a1_wait:
    in      al, 0x64
    test    al, 0x01
    loope   bios_post_8042_a1_wait
    jz      bios_post_8042_a1_done
    in      al, 0x60
    xor     al, 0x38
    jnz     bios_post_8042_a1_done
    or      bp, strict word 0x0000
bios_post_8042_a1_done:
    mov     al, 0xFF
    out     0x64, al
    mov     sp, 0xD826
    JMP_ABS 0xF659

times 0xD826 - ($ - rom_start) db 0xFF
bios_post_8042_ff_return:
    dw      0xD828
bios_post_keyboard_init_done:
    mov     al, 0x09
    out     0x80, al
    JMP_ABS 0x1AF8

; ---------------------------------------------------------------------------
; F000:D82F — first 8042 command/data exchange after POST 09h.
times 0xD82F - ($ - rom_start) db 0xFF
bios_post_8042_command_60:
    mov     al, 0x60
    out     0x64, al
    nop
    mov     sp, 0xD83A
    JMP_ABS 0xF659

times 0xD83A - ($ - rom_start) db 0xFF
bios_post_8042_command_60_return:
    dw      0xD83C
bios_post_8042_command_60_continue:
    mov     al, 0x0A
    out     0x80, al
    test    byte [cs:0x8280], 0x10
    mov     al, 0x55
    jz      short bios_post_8042_command_data
    mov     al, 0x74
bios_post_8042_command_data:
    out     0x60, al
    mov     sp, 0xD854
    JMP_ABS 0xF659

times 0xD854 - ($ - rom_start) db 0xFF
bios_post_8042_command_data_return:
    dw      0xD856
times 0xD856 - ($ - rom_start) db 0xFF
bios_post_8042_command_0b:
    mov     al, 0x0B
    out     0x80, al
    test    byte [cs:0x8280], 0x20
    mov     al, 0xC8
    jz      short bios_post_8042_command_c8
    mov     al, 0xC9
bios_post_8042_command_c8:
    out     0x64, al
    mov     sp, 0xD86E
    JMP_ABS 0xF659

times 0xD86E - ($ - rom_start) db 0xFF
bios_post_8042_command_0b_return:
    dw      0xD870
bios_post_8042_command_0b_continue:
    mov     al, 0x0C
    out     0x80, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0xFF
    out     0x64, al
    mov     sp, 0xD882
    JMP_ABS 0xF659

times 0xD882 - ($ - rom_start) db 0xFF
bios_post_cmos_8f_55_return:
    dw      0xD884
bios_post_cmos_8f_55_continue:
    mov     al, 0x0D
    out     0x80, al
    mov     ax, 0x558F
    nop
    mov     sp, 0xD892
    JMP_ABS 0xEE9D

times 0xD892 - ($ - rom_start) db 0xFF
bios_post_cmos_8f_55_read_return:
    dw      0xD894
bios_post_cmos_8f_55_read_continue:
    mov     sp, 0xD89A
    JMP_ABS 0xEE94

times 0xD89A - ($ - rom_start) db 0xFF
bios_post_cmos_8f_55_compare_return:
    dw      0xD89C
bios_post_cmos_8f_55_compare_continue:
    xor     al, ah
    jnz     short bios_post_cmos_8f_mismatch
    mov     ax, 0xAA8F
    nop
    mov     sp, 0xD8AA
    JMP_ABS 0xEE9D

times 0xD8AA - ($ - rom_start) db 0xFF
bios_post_cmos_8f_aa_write_return:
    dw      0xD8AC
bios_post_cmos_8f_aa_write_continue:
    mov     sp, 0xD8B2
    JMP_ABS 0xEE94

times 0xD8B2 - ($ - rom_start) db 0xFF
bios_post_cmos_8f_aa_read_return:
    dw      0xD8B4
bios_post_cmos_8f_aa_read_continue:
    xor     al, ah
    jz      short bios_post_cmos_8e_read
bios_post_cmos_8f_mismatch:
    mov     bp, 0x000A
    JMP_ABS 0xF4A5

bios_post_cmos_8e_read:
    mov     al, 0x0E
    out     0x80, al
    mov     al, 0x8D
    mov     sp, 0xD8CA
    JMP_ABS 0xEE94

times 0xD8CA - ($ - rom_start) db 0xFF
bios_post_cmos_8e_read_return:
    dw      0xD8CC
bios_post_cmos_8e_read_continue:
    or      al, al
    mov     ax, 0x8E8E
    nop
    mov     sp, 0xD8D8
    JMP_ABS 0xEE94

times 0xD8D8 - ($ - rom_start) db 0xFF
bios_post_cmos_8e_flags_return:
    dw      0xD8DA
bios_post_cmos_8e_flags_continue:
    js      short bios_post_cmos_8e_negative
    or      bp, 0x0008
    or      al, 0xDC
    jmp     short bios_post_cmos_8e_flags_done
bios_post_cmos_8e_negative:
    or      al, al
    js      short bios_post_cmos_8e_sign
    JMP_ABS 0x868B
bios_post_cmos_8e_zero:
    jz      short bios_post_cmos_8e_mask
    or      al, 0x5C
    or      bp, 0x0020
    jmp     short bios_post_cmos_8e_flags_done
bios_post_cmos_8e_sign:
    or      bp, 0x0010
    jmp     short bios_post_cmos_8e_flags_done
bios_post_cmos_8e_mask:
    and     al, 0x8B
bios_post_cmos_8e_flags_done:
    and     al, 0xFE
    xchg    ah, al
    mov     sp, 0xD904
    JMP_ABS 0xEE9D

times 0xD904 - ($ - rom_start) db 0xFF
bios_post_cmos_8e_write_return:
    dw      0xD906
bios_post_cmos_8e_write_continue:
    mov     al, 0x0F
    out     0x80, al
    JMP_ABS 0x8400

; Separate D90Dh POST entry: CMOS 8Bh read/modify/write sequence.
times 0xD90D - ($ - rom_start) db 0xFF
bios_post_cmos_8b_update:
    mov     al, 0x10
    out     0x80, al
    mov     ax, 0x8B8B
    mov     sp, 0xD91A
    JMP_ABS 0xEE94

times 0xD91A - ($ - rom_start) db 0xFF
bios_post_cmos_8b_read_return:
    dw      0xD91C
bios_post_cmos_8b_read_continue:
    and     al, 0x07
    xchg    ah, al
    mov     sp, 0xD926
    JMP_ABS 0xEE9D

times 0xD926 - ($ - rom_start) db 0xFF
bios_post_cmos_8c_read_return:
    dw      0xD928
bios_post_cmos_8c_read_continue:
    mov     al, 0x8C
    mov     sp, 0xD930
    JMP_ABS 0xEE94

times 0xD930 - ($ - rom_start) db 0xFF
bios_post_cmos_8a_read_return:
    dw      0xD932
bios_post_cmos_8a_read_continue:
    mov     ax, 0x8A8A
    nop
    mov     sp, 0xD93C
    JMP_ABS 0xEE94

times 0xD93C - ($ - rom_start) db 0xFF
bios_post_cmos_8a_compare_return:
    dw      0xD93E
bios_post_cmos_8a_compare_continue:
    and     al, 0x0F
    jnz     short bios_post_cmos_8a_enable_keyboard
    mov     al, 0x26
    xchg    ah, al
    mov     sp, 0xD94C
    JMP_ABS 0xEE9D

times 0xD94C - ($ - rom_start) db 0xFF
bios_post_keyboard_enable_return:
    dw      0xD94E
bios_post_keyboard_enable_continue:
bios_post_cmos_8a_enable_keyboard:
    mov     al, 0xAE
    out     0x64, al
    mov     sp, 0xD958
    JMP_ABS 0xF659

times 0xD958 - ($ - rom_start) db 0xFF
bios_post_keyboard_ack_return:
    dw      0xD95A
bios_post_keyboard_ack_continue:
    mov     cx, 0x4000
bios_post_keyboard_ack_wait:
    in      al, 0x60
    cmp     al, 0x52
    loopne  bios_post_keyboard_ack_wait
    jnz     bios_post_keyboard_disable
    mov     ax, 0x8E8E
    mov     sp, 0xD96E
    JMP_ABS 0xEE94

times 0xD96E - ($ - rom_start) db 0xFF
bios_post_cmos_8e_update_return:
    dw      0xD970
bios_post_cmos_8e_update_continue:
    or      al, 0x01
    xchg    ah, al
    mov     sp, 0xD97A
    JMP_ABS 0xEE9D

times 0xD97A - ($ - rom_start) db 0xFF
bios_post_keyboard_disable_return:
    dw      0xD97C
bios_post_keyboard_disable:
    mov     al, 0xAD
    out     0x64, al
    mov     sp, 0xD986
    JMP_ABS 0xF659

times 0xD986 - ($ - rom_start) db 0xFF
bios_post_pic_setup_return:
    dw      0xD988
bios_post_pic_setup_continue:
    mov     al, 0x11
    out     0x80, al
    mov     al, 0x04
    out     0x08, al
    jcxz    $+2
    jcxz    $+2
    out     0xD0, al
    mov     bx, 0x0870
    nop
    mov     sp, 0xD9A0
    JMP_ABS 0xEEEF

times 0xD9A0 - ($ - rom_start) db 0xFF
bios_post_chipset_io_return:
    dw      0xD9A2
bios_post_chipset_io_continue:
    mov     al, 0x12
    out     0x80, al
    xor     ax, ax
    mov     dx, 0x03D8
    out     dx, al
    jcxz    $+2
    jcxz    $+2
    inc     ax
    mov     dl, 0xB8
    out     dx, al
    jcxz    $+2
    jcxz    $+2
    mov     dl, 0xBA
    in      al, dx
    jcxz    $+2
    jcxz    $+2
    mov     dl, 0xDA
    in      al, dx
    jcxz    $+2
    jcxz    $+2
    mov     dl, 0xC0
    mov     al, 0
    out     dx, al
    jcxz    $+2
    jcxz    $+2
    xor     ax, ax
    mov     es, ax
    mov     ds, ax
    mov     al, 0x13
    out     0x80, al
    JMP_ABS 0x1AFB

; F000:D9DCh — PIT channel-2 latch/readback test and channel-0 setup.
times 0xD9DC - ($ - rom_start) db 0xFF
bios_post_pit_channel2_test:
    mov     al, 0x14
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    xor     ax, ax
    mov     es, ax
    mov     ds, ax
    mov     al, 0xFC
    out     0x61, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0xB4
    out     0x43, al
    mov     al, 0x55
    jcxz    $+2
    jcxz    $+2
    out     0x42, al
    mov     al, 0xAA
    jcxz    $+2
    jcxz    $+2
    out     0x42, al
    mov     al, 0x80
    jcxz    $+2
    jcxz    $+2
    out     0x43, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x42
    mov     ah, al
    jcxz    $+2
    jcxz    $+2
    in      al, 0x42
    cmp     ax, 0x55AA
    jz      short bios_post_pit_channel2_ok
    test    byte [cs:0x8280], 0x80
    jz      short bios_post_pit_channel2_ok
    or      bp, 0x0001
bios_post_pit_channel2_ok:
    mov     al, 0x15
    out     0x80, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x36
    out     0x43, al
    mov     al, 0
    jcxz    $+2
    jcxz    $+2
    out     0x40, al
    jcxz    $+2
    jcxz    $+2
    out     0x40, al
    test    byte [cs:0x8280], 0x80
    jz      short bios_post_pit_test_done
    mov     al, [cs:0x8285]
    or      al, al
    jnz     short bios_post_pit_test_done
    xor     bx, bx
    mov     ah, 0x10
    mov     dx, 0x0061
    nop
    mov     sp, 0xDA64
    JMP_ABS 0xF598

; The F598h timing helper returns through this inline word.
times 0xDA64 - ($ - rom_start) db 0xFF
bios_post_pit_timing_return:
    dw      0xDA66
bios_post_pit_timing_continue:
    jcxz    bios_post_pit_feature_check
    mov     al, 0x1A
    out     0x80, al
bios_post_pit_wait_high:
    in      al, 0x61
    test    ah, al
    jz      short bios_post_pit_wait_high
    xor     cx, cx
bios_post_pit_wait_low:
    in      al, 0x61
    test    ah, al
    loopne  bios_post_pit_wait_low
    xchg    bx, cx
bios_post_pit_wait_second_high:
    in      al, 0x61
    test    ah, al
    loope   bios_post_pit_wait_second_high
    sub     cx, bx
    jns     short bios_post_pit_delta_ready
    neg     cx
bios_post_pit_delta_ready:
    cmp     cx, 0x000A
    jc      short bios_post_pit_test_done
bios_post_pit_feature_check:
    test    byte [cs:0x8280], 0x80
    jz      short bios_post_pit_test_done
    mov     bp, 0x0001
    JMP_ABS 0xF4A5
bios_post_pit_test_done:
    mov     al, 0x1B
    out     0x80, al
    JMP_ABS 0x5BF8

; F000:DAA2-DFFF — verified zero-filled data/padding area.
times 0xE000 - ($ - rom_start) db 0x00

; F000:E000 — alternate far-entry stub to F000:E005.
    jmp     0xF000:0xE005
; F000:E005 — alternate near-entry stub into the POST continuation.
    jmp     near 0xF73B
times 0xE00E - ($ - rom_start) db 0x00
bios_ibm_compatibility_notice:
    db "IBM COMPATIBLE IBM IS A TRADEMARK OF INTERNATIONAL BUSINESS MACHINES CORP."
times 0xE05B - ($ - rom_start) db 0x00
; F000:E05B — reset gateway.
times 0xE05B - ($ - rom_start) db 0xFF
reset_gateway:
    jmp     near bios_post_entry
reset_gateway_end:
%if (reset_gateway_end - reset_gateway) != 3
    %error "Unexpected reset gateway size"
%endif

; ---------------------------------------------------------------------------
; F000:E93Ch — PIT channel-2 transition wait used by POST speaker diagnostics.
times 0xE93C - ($ - rom_start) db 0xFF
bios_post_pit_transition_wait:
    push    ax
    mov     al, [cs:0x8285]
    or      al, al
    jz      short bios_post_pit_transition_wait_high
bios_post_pit_delay_outer:
    mov     al, [cs:0x8285]
bios_post_pit_delay_inner:
    dec     al
    jnz     short bios_post_pit_delay_inner
    dec     cx
    jnz     short bios_post_pit_delay_outer
    jmp     short bios_post_pit_transition_wait_done
bios_post_pit_transition_wait_high:
    in      al, 0x61
    test    al, 0x10
    jz      short bios_post_pit_transition_wait_high
    dec     cx
    jz      short bios_post_pit_transition_wait_done
bios_post_pit_transition_wait_low:
    in      al, 0x61
    test    al, 0x10
    jnz     short bios_post_pit_transition_wait_low
    dec     cx
    jnz     short bios_post_pit_transition_wait_high
bios_post_pit_transition_wait_done:
    pop     ax
    ret

%if ($ - rom_start) != 0xE966
    %error "PIT channel-2 transition helper must end at E966h"
%endif

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

; ---------------------------------------------------------------------------
; F000:F4A5 — fatal POST diagnostic loop and speaker alarm.
; The stack is deliberately pointed into the delay instructions at F4ACh.
; After each 128-cycle speaker burst, JMP SP enters that stack-threaded delay.
times 0xF4A5 - ($ - rom_start) db 0xFF
bios_post_fatal_error:
    mov     dx, bp
bios_post_fatal_error_stack_setup:
    mov     sp, 0xF4AC
    jmp     short bios_post_fatal_beep

bios_post_fatal_stack_delay_1:
    loop    bios_post_fatal_stack_delay_1
bios_post_fatal_stack_delay_2:
    loop    bios_post_fatal_stack_delay_2
bios_post_fatal_stack_delay_3:
    loop    bios_post_fatal_stack_delay_3
    dec     dx
    jnz     short bios_post_fatal_error_stack_setup
    mov     dx, 0x0006
bios_post_fatal_stack_delay_4:
    loop    bios_post_fatal_stack_delay_4
    dec     dx
    jnz     short bios_post_fatal_stack_delay_4
    in      al, 0x80
    jcxz    $+2
    jcxz    $+2
    out     0x80, al
    jcxz    $+2
    jcxz    $+2
    mov     ax, si
    out     0x81, al
    jcxz    $+2
    jcxz    $+2
    mov     al, ah
    out     0x82, al
    jcxz    $+2
    jcxz    $+2
    mov     ax, di
    out     0x83, al
    jcxz    $+2
    jcxz    $+2
    mov     al, ah
    out     0x84, al
    jmp     short bios_post_fatal_error

bios_post_fatal_beep:
    mov     bx, 0x0080
bios_post_fatal_beep_loop:
    in      al, 0x61
    and     al, 0xFE
    jcxz    $+2
    jcxz    $+2
    or      al, 0x02
    out     0x61, al
    mov     cx, 0x00E0
bios_post_fatal_beep_on_delay:
    loop    bios_post_fatal_beep_on_delay
    and     al, 0xFD
    out     0x61, al
    mov     cx, 0x00D0
bios_post_fatal_beep_off_delay:
    loop    bios_post_fatal_beep_off_delay
    dec     bx
    jnz     short bios_post_fatal_beep_loop
    jmp     sp

%if ($ - rom_start) != 0xF509
    %error "Fatal POST handler / JMP SP trampoline must end at F509h"
%endif

; F000:F509 — overlapping video-reset entry (XOR AX,AX; INT 10h).
bios_post_fatal_video_entry:
    xor     ax, ax
    int     0x10
bios_post_fatal_text_entry:
    call    bios_post_print_cs_string
    mov     si, 0x737E
    call    bios_post_print_cs_string
    call    bios_post_read_8042_status
    test    al, 0x20
    jnz     short bios_post_fatal_keyboard_ready
bios_post_fatal_keyboard_wait:
    cli
    call    bios_post_speaker_tone_5
    loop    bios_post_fatal_keyboard_wait
    jmp     short bios_post_fatal_keyboard_wait
bios_post_fatal_keyboard_ready:
    mov     sp, 0xF52A
    jmp     short bios_post_fatal_beep
bios_post_fatal_halt:
    sti
    hlt
    jmp     short bios_post_fatal_halt

%if ($ - rom_start) != 0xF52E
    %error "Fatal POST text/halt continuation must end at F52Eh"
%endif

; F000:F52E — NUL-terminated CS:SI string and teletype output helpers.
bios_post_print_cs_string:
    cli
    cld
bios_post_print_cs_string_loop:
    cs lodsb
    and     al, al
    jz      short bios_post_print_cs_string_done
    call    bios_post_print_char
    jmp     short bios_post_print_cs_string_loop
bios_post_print_cs_string_done:
    ret
bios_post_print_char:
    mov     ah, 0x0E
    int     0x10

; F000:F540 — restore CMOS index and speaker state.
bios_post_restore_cmos_index:
    cli
    cld
    mov     al, 0x8D
    out     0x70, al
    call    bios_post_speaker_off
    ret

; F000:F54A/F571 — PIT channel-2 speaker tone helpers.
bios_post_speaker_tone_4:
    mov     al, 0xB6
    out     0x43, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x04
    out     0x42, al
    jcxz    $+2
    jcxz    $+2
    out     0x42, al
    in      al, 0x61
    push    ax
    jcxz    $+2
    jcxz    $+2
    or      al, 0x03
    out     0x61, al
    mov     cx, 0x3000
    call    0xE93C
    pop     ax
    out     0x61, al
    ret

bios_post_speaker_tone_5:
    mov     al, 0xB6
    out     0x43, al
    jcxz    $+2
    jcxz    $+2
    mov     al, 0x05
    out     0x42, al
    jcxz    $+2
    jcxz    $+2
    out     0x42, al
    in      al, 0x61
    push    ax
    jcxz    $+2
    jcxz    $+2
    or      al, 0x03
    out     0x61, al
    mov     cx, 0x2000
    call    0xE93C
    pop     ax
    out     0x61, al
    ret

; F000:F598 — wait for selected port bits to clear/set.
bios_post_wait_port_bits:
    xor     cx, cx
bios_post_wait_port_bits_clear:
    in      al, dx
    test    ah, al
    loope   bios_post_wait_port_bits_clear
    jz      short bios_post_wait_port_bits_done
    xor     cx, cx
bios_post_wait_port_bits_set:
    in      al, dx
    test    ah, al
    loopne  bios_post_wait_port_bits_set
bios_post_wait_port_bits_done:
    ret

; F000:F5A9 — force speaker data/gate bits off.
bios_post_speaker_off:
    in      al, 0x61
    or      al, 0x0C
    jcxz    $+2
    jcxz    $+2
    out     0x61, al
    and     al, 0xF3
    jcxz    $+2
    jcxz    $+2
    out     0x61, al
    ret

; F000:F5BC/F5C9 — 8042 command/data exchange and response compare.
bios_post_8042_compare_command:
    call    bios_post_8042_write_command_byte
    jnz     short bios_post_8042_compare_done
    call    bios_post_8042_read_response
    jz      short bios_post_8042_compare_success
    cmp     al, ah
bios_post_8042_compare_done:
    ret

bios_post_8042_compare_data:
    call    bios_post_8042_write_data
    jnz     short bios_post_8042_compare_data_done
    call    bios_post_8042_read_response
    jz      short bios_post_8042_compare_success
    cmp     al, ah
bios_post_8042_compare_data_done:
    ret

bios_post_8042_compare_success:
    or      sp, sp
    ret

; F000:F5D9/F5E9 — read KBC status/data then compare command response.
bios_post_read_8042_status:
    in      al, 0x64
    test    al, 0x01
    jz      short bios_post_read_8042_status_command
    jcxz    $+2
    in      al, 0x60
bios_post_read_8042_status_command:
    mov     al, 0xC0
    call    bios_post_8042_compare_command
    ret

bios_post_read_8042_output_port:
    in      al, 0x64
    test    al, 0x01
    jz      short bios_post_read_8042_output_command
    jcxz    $+2
    in      al, 0x60
bios_post_read_8042_output_command:
    mov     al, 0xD0
    call    bios_post_8042_compare_command
    ret

; F000:F5F9 — read the 8042 response byte.
bios_post_8042_read_response:
    call    bios_post_8042_wait_output_ready
    in      al, 0x60
    ret

; F000:F5FF — bounded 8042 output-buffer wait with twelve retries.
bios_post_8042_wait_output_ready:
    mov     cx, 0x000C
bios_post_8042_wait_output_retry:
    push    cx
    xor     cx, cx
bios_post_8042_wait_output_inner:
    in      al, 0x64
    test    al, 0x01
    loope   bios_post_8042_wait_output_inner
    pop     cx
    loope   bios_post_8042_wait_output_retry
    ret

%if ($ - rom_start) != 0xF60F
    %error "Reconstructed POST error/KBC helper region must end at F60Fh"
%endif

; ---------------------------------------------------------------------------
; F000:F60F — bounded 8042 output-buffer read helper.
times 0xF60F - ($ - rom_start) db 0xFF
bios_8042_read_output:
    mov     ah, 0x0C
    xor     cx, cx
bios_8042_read_output_wait:
    in      al, 0x64
    test    al, 0x01
    loope   bios_8042_read_output_wait
    jnz     bios_8042_read_output_data
    dec     ah
    jnz     bios_8042_read_output_wait
bios_8042_read_output_data:
    in      al, 0x60
    ret

; F000:F622-F658 — 8042 command/data transactions.
times 0xF622 - ($ - rom_start) db 0xFF
bios_post_8042_write_command:
    call    bios_post_8042_write_command_byte
    jnz     short bios_post_8042_write_command_done
    db      0x8A, 0xC4                 ; mov al, ah
    call    bios_post_8042_write_data
bios_post_8042_write_command_done:
    ret

bios_post_8042_write_output_port:
    db      0x8A, 0xE0                 ; mov ah, al
    mov     al, 0xD1
    call    bios_post_8042_write_command
    ret

bios_post_8042_write_command_byte:
    push    ax
    call    bios_8042_wait_input_empty
    pop     ax
    jnz     short bios_post_8042_write_command_byte_done
    out     0x64, al
    push    ax
    call    bios_8042_wait_input_empty
    pop     ax
bios_post_8042_write_command_byte_done:
    ret

bios_post_8042_write_data:
    push    ax
    call    bios_8042_wait_input_empty
    pop     ax
    jnz     short bios_post_8042_write_data_done
    out     0x60, al
    call    bios_8042_wait_input_empty
bios_post_8042_write_data_done:
    ret

bios_post_8042_write_output_port_data:
    mov     ah, al
    mov     al, 0x60
    call    bios_post_8042_write_command
    ret

%if ($ - rom_start) != 0xF659
    %error "8042 command/data transaction helpers must end at F659h"
%endif

; F000:F659 — 8042 input-buffer-empty wait helper.
times 0xF659 - ($ - rom_start) db 0xFF
bios_8042_wait_input_empty:
    xor     cx, cx
bios_8042_wait_input_empty_first:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_wait_input_empty_first
    jz      bios_8042_wait_input_empty_done
bios_8042_wait_input_empty_second:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_wait_input_empty_second
bios_8042_wait_input_empty_done:
    ret

; F000:F66Ah/F66Eh — 8042 A20 output-port enable/disable helpers.
times 0xF66A - ($ - rom_start) db 0xFF
bios_8042_a20_enable:
    mov     ah, 0xDF
    jmp     short bios_8042_a20_write
bios_8042_a20_disable:
    mov     ah, 0xDD
bios_8042_a20_write:
    xor     cx, cx
bios_8042_a20_wait_command:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_a20_wait_command
    mov     al, 0xD1
    out     0x64, al
    xor     cx, cx
bios_8042_a20_wait_data:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_a20_wait_data
    mov     al, ah
    out     0x60, al
    xor     cx, cx
bios_8042_a20_wait_finish:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_a20_wait_finish
    ret

; FFFF:0000 reset vector -> F000:E05B.
times 0xFFF0 - ($ - rom_start) db 0xFF
bios_reset_vector:
    jmp     0xF000:reset_gateway

times ROM_SIZE - ($ - rom_start) db 0xFF
%if ($ - rom_start) != ROM_SIZE
    %error "Incorrect BIOS ROM size"
%endif
