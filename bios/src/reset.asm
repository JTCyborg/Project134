; Project134 — AMI486 BIOS reconstruction
; NASM-only executable implementation. Reference ROM is analysis-only.
; Unimplemented gaps are inherited byte-for-byte from ami486.bin until replaced by verified native code.

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
incbin  "ami486.bin", ($ - rom_start), (0x19AB - ($ - rom_start)) ; inherited reference bytes up to 19ABh
bios_callback_jmp_di:
    jmp     di
bios_callback_ret_19ad:
    ret
bios_callback_ret_19ae:
    ret
bios_callback_ret_19af:
    ret

; F000:1AF8 — POST continuation trampoline into the D82Fh 8042 sequence.
incbin  "ami486.bin", ($ - rom_start), (0x1AF8 - ($ - rom_start)) ; inherited reference bytes up to 1AF8h
bios_post_8042_continuation:
    JMP_ABS 0xD82F

; ---------------------------------------------------------------------------
; F000:1AFB — CMOS B3h profile selection and PIT/speaker initialization.
incbin  "ami486.bin", ($ - rom_start), (0x1AFB - ($ - rom_start)) ; inherited reference bytes up to 1AFBh
bios_cmos_b3_profile_entry:
    mov     al, 0xB3
    nop
    mov     sp, 0x1B04
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0x1B04 - ($ - rom_start)) ; inherited reference bytes up to 1B04h
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
    db      0x2B, 0xCE                 ; sub cx, si
    shr     cx, 1
bios_cmos_profile_table_write:
    cs lodsw
    mov     sp, 0x1B2A
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x1B2A - ($ - rom_start)) ; inherited reference bytes up to 1B2Ah
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
    db      0x33, 0xFF                 ; xor di, di
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
incbin  "ami486.bin", ($ - rom_start), (0x2065 - ($ - rom_start)) ; inherited reference bytes up to 2065h
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
incbin  "ami486.bin", ($ - rom_start), (0x208D - ($ - rom_start)) ; inherited reference bytes up to 208Dh
bios_ali_profile_apply:
    mov     ax, 0xC503
    mov     sp, 0x2096
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x2096 - ($ - rom_start)) ; inherited reference bytes up to 2096h
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
    db      0x8A, 0xD8                 ; mov bl, al
    cmp     al, 0x26
    db      0x0F, 0x85, 0x06, 0x00      ; jne near 20B7h
    dec     cx
    add     si, 2
    jmp     short bios_ali_profile_record_loop

bios_ali_profile_record_write:
    cs lodsw
    db      0x8A, 0xC3                 ; mov al, bl
    nop
    mov     sp, 0x20C2
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x20C2 - ($ - rom_start)) ; inherited reference bytes up to 20C2h
bios_ali_profile_write_return:
    dw      0x20C4
bios_ali_profile_write_continue:
    loop    bios_ali_profile_record_loop
    mov     sp, 0x20CC
    jmp     bios_8042_a20_enable

incbin  "ami486.bin", ($ - rom_start), (0x20CC - ($ - rom_start)) ; inherited reference bytes up to 20CCh
bios_ali_profile_a20_return:
    dw      0x20CE
bios_ali_profile_a20_continue:
    mov     bx, 0x0800
    nop
    mov     sp, 0x20D8
    JMP_ABS 0xEEEF

incbin  "ami486.bin", ($ - rom_start), (0x20D8 - ($ - rom_start)) ; inherited reference bytes up to 20D8h
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

incbin  "ami486.bin", ($ - rom_start), (0x20FA - ($ - rom_start)) ; inherited reference bytes up to 20FAh
bios_ali_profile_write_pm_return:
    dw      0x20FC

; F000:8280 — recovered original BIOS configuration bytes.
; These fields are read by POST code at 8280h..8286h.
; F000:20FCh — protected-mode memory alias probes and stack-threaded chipset setup.
; The return-address words below are data consumed by RET in the shared I/O helpers.
bios_memory_alias_probe:
    mov     dl, 0xFF
    db      0x26,0x66,0xC7,0x06,0x00,0x00,0x55,0x55,0xAA,0xAA ; mov dword [es:0000],AAAA5555h
    db      0x26,0x66,0xC7,0x06,0x00,0x01,0xFF,0xFF,0xFF,0xFF ; mov dword [es:0100],FFFFFFFFh
    db      0x26,0x66,0x81,0x3E,0x00,0x00,0x55,0x55,0xAA,0xAA ; cmp dword [es:0000],AAAA5555h
    jnz     near bios_memory_alias_low_fail
    db      0x26,0x66,0xC7,0x06,0x00,0x00,0xAA,0xAA,0x55,0x55 ; mov dword [es:0000],5555AAAAh
    db      0x26,0x66,0xC7,0x06,0x00,0x01,0xFF,0xFF,0xFF,0xFF ; mov dword [es:0100],FFFFFFFFh
    db      0x26,0x66,0x81,0x3E,0x00,0x00,0xAA,0xAA,0x55,0x55 ; cmp dword [es:0000],5555AAAAh
    jnz     near bios_memory_alias_low_fail
    mov     dl, 0x00
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x80,0x00,0xAA,0xAA,0x55,0x55 ; cmp dword [es:00800000],5555AAAAh
    jz      near bios_memory_alias_low_fail
    mov     dl, 0x02
    db      0x26,0x66,0x81,0x3E,0x00,0x08,0xAA,0xAA,0x55,0x55 ; cmp dword [es:0800],5555AAAAh
    jz      near bios_memory_alias_low_fail
    mov     dl, 0x01
    db      0x26,0x66,0x81,0x3E,0x00,0x10,0xAA,0xAA,0x55,0x55 ; cmp dword [es:1000],5555AAAAh
    jz      near bios_memory_alias_low_fail
    mov     dl, 0x03
    db      0x26,0x66,0x81,0x3E,0x00,0x20,0xAA,0xAA,0x55,0x55 ; cmp dword [es:2000],5555AAAAh
    jz      near bios_memory_alias_low_fail
    mov     dl, 0x04
bios_memory_alias_low_fail:
    mov     dh, 0xFF
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x00,0x00,0x04,0x55,0x55,0xAA,0xAA ; mov dword [es:04000000],AAAA5555h
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x01,0x00,0x04,0xFF,0xFF,0xFF,0xFF ; mov dword [es:04000100],FFFFFFFFh
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x00,0x04,0x55,0x55,0xAA,0xAA ; cmp dword [es:04000000],AAAA5555h
    jnz     near bios_memory_alias_high_fail
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x00,0x00,0x04,0xAA,0xAA,0x55,0x55 ; mov dword [es:04000000],5555AAAAh
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x01,0x00,0x04,0xFF,0xFF,0xFF,0xFF ; mov dword [es:04000100],FFFFFFFFh
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x00,0x04,0xAA,0xAA,0x55,0x55 ; cmp dword [es:04000000],5555AAAAh
    jnz     near bios_memory_alias_high_fail
    mov     dh, 0x00
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x80,0x04,0xAA,0xAA,0x55,0x55 ; cmp dword [es:04800000],5555AAAAh
    jz      near bios_memory_alias_high_fail
    mov     dh, 0x02
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x08,0x00,0x04,0xAA,0xAA,0x55,0x55 ; cmp dword [es:04000800],5555AAAAh
    jz      near bios_memory_alias_high_fail
    mov     dh, 0x01
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x10,0x00,0x04,0xAA,0xAA,0x55,0x55 ; cmp dword [es:04001000],5555AAAAh
    jz      near bios_memory_alias_high_fail
    mov     dh, 0x03
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x20,0x00,0x04,0xAA,0xAA,0x55,0x55 ; cmp dword [es:04002000],5555AAAAh
    jz      near bios_memory_alias_high_fail
    mov     dh, 0x04
bios_memory_alias_high_fail:
    mov     ax, 0x1616
    mov     sp, 0x2236
    JMP_ABS 0x8DCF
    dw      0x2238
    or      al, 0x30
    xchg    ah, al
    mov     sp, 0x2242
    JMP_ABS 0x8DDC
    dw      0x2244
    mov     ax, 0x4411
    nop
    mov     sp, 0x224E
    JMP_ABS 0x8DDC
    dw      0x2250

; 2250h — second low/high alias pass; initialize BL selector and store through ES.
bios_memory_alias_second_pass:
    mov     bl, 0xFF
    db      0x26,0x66,0xC7,0x06,0x00,0x00,0x55,0x55,0xAA,0xAA ; mov dword [es:0000],AAAA5555h
    db      0x26,0x66,0xC7,0x06,0x00,0x01,0xFF,0xFF,0xFF,0xFF
    db      0x26,0x66,0x81,0x3E,0x00,0x00,0x55,0x55,0xAA,0xAA
    jnz     near bios_memory_alias_second_low_fail
    db      0x26,0x66,0xC7,0x06,0x00,0x00,0xAA,0xAA,0x55,0x55
    db      0x26,0x66,0xC7,0x06,0x00,0x01,0xFF,0xFF,0xFF,0xFF
    db      0x26,0x66,0x81,0x3E,0x00,0x00,0xAA,0xAA,0x55,0x55
    jnz     near bios_memory_alias_second_low_fail
    mov     bl, 0x00
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x80,0x00,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_low_fail
    mov     bl, 0x02
    db      0x26,0x66,0x81,0x3E,0x00,0x08,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_low_fail
    mov     bl, 0x01
    db      0x26,0x66,0x81,0x3E,0x00,0x10,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_low_fail
    mov     bl, 0x03
    db      0x26,0x66,0x81,0x3E,0x00,0x20,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_low_fail
    mov     bl, 0x04
bios_memory_alias_second_low_fail:
    mov     bh, 0xFF
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x00,0x00,0x04,0x55,0x55,0xAA,0xAA
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x01,0x00,0x04,0xFF,0xFF,0xFF,0xFF
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x00,0x04,0x55,0x55,0xAA,0xAA
    jnz     near bios_memory_alias_second_high_fail
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x00,0x00,0x04,0xAA,0xAA,0x55,0x55
    db      0x26,0x67,0x66,0xC7,0x05,0x00,0x01,0x00,0x04,0xFF,0xFF,0xFF,0xFF
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x00,0x04,0xAA,0xAA,0x55,0x55
    jnz     near bios_memory_alias_second_high_fail
    mov     bh, 0x00
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x00,0x80,0x04,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_high_fail
    mov     bh, 0x02
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x08,0x00,0x04,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_high_fail
    mov     bh, 0x01
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x10,0x00,0x04,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_high_fail
    mov     bh, 0x03
    db      0x26,0x67,0x66,0x81,0x3D,0x00,0x20,0x00,0x04,0xAA,0xAA,0x55,0x55
    jz      near bios_memory_alias_second_high_fail
    mov     bh, 0x04
bios_memory_alias_second_high_fail:
    and     dx, 0x0F0F
    db      0x8A, 0xE6                 ; mov ah, dh
    shl     ah, 4
    db      0x0A, 0xE2                 ; or ah, dl
    mov     al, 0x10
    mov     sp, 0x2394
    JMP_ABS 0x8DDC
    dw      0x2396
    and     bx, 0x0F0F
    db      0x8A, 0xE7                 ; mov ah, bh
    shl     ah, 4
    db      0x0A, 0xE3                 ; or ah, bl
    mov     al, 0x11
    nop
    mov     sp, 0x23AA
    JMP_ABS 0x8DDC
    dw      0x23AC
    mov     ax, 0x0016
    nop
    mov     sp, 0x23B6
    JMP_ABS 0x8DDC
    dw      0x23B8
    mov     ax, 0x0010
    mov     es, ax
    mov     eax, cr0
    and     al, 0xFE
    mov     cr0, eax
    jmp     short $+2
    nop
    mov     sp, 0x23CE
    JMP_ABS 0xF66E
    dw      0x23D0
    mov     bx, 0x0400
    nop
    mov     sp, 0x23DA
    JMP_ABS 0x552D
    dw      0x23DC
    jz      short bios_memory_probe_success
    mov     bp, 0x0003
    JMP_ABS 0xF4A5
bios_memory_probe_success:
    mov     ax, 0x0030
    mov     ss, ax
    mov     sp, 0x0100
    call    0x240A
    call    0x2495
    call    0x29ED
    jz      short bios_memory_config_skip
    call    0x8F12
    call    0x2537
bios_memory_config_skip:
    db      0x2B, 0xC0                 ; sub ax, ax
    mov     ds, ax
    mov     es, ax
    mov     ax, cs
    mov     ss, ax
    JMP_ABS 0xD9DC

%if ($ - rom_start) != 0x240A
    %error "Protected-mode memory alias probe region must end at 240Ah"
%endif
; F000:240Ah–2536h — shadow-window workers and CMOS-gated ALi register conversion.
bios_shadow_copy_f000:
    mov     bx, 0xF000
    mov     dl, 0xC0
    mov     cx, 0x8000
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_c000:
    mov     bx, 0xC000
    mov     cx, 0x4000
    mov     dl, 0x01
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_c800:
    mov     bx, 0xC800
    mov     cx, 0x4000
    mov     dl, 0x02
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_d000:
    mov     bx, 0xD000
    mov     cx, 0x4000
    mov     dl, 0x04
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_d800:
    mov     bx, 0xD800
    mov     cx, 0x4000
    mov     dl, 0x08
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_e000:
    mov     bx, 0xE000
    mov     cx, 0x4000
    mov     dl, 0x10
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_c800_alt:
    mov     bx, 0xC800
    mov     cx, 0x4000
    mov     dl, 0x20
    jmp     short bios_shadow_copy_common
    nop
bios_shadow_copy_common:
    push    es
    push    ds
    mov     ax, 0x1313
    call    near 0x8DCF
    db      0x0A, 0xC2                 ; or al, dl
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    mov     ax, 0x1414
    call    near 0x8DCF
    and     al, 0xFC
    or      al, 0x02
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    db      0x8B, 0xC3                 ; mov ax, bx
    mov     ds, ax
    mov     es, ax
    db      0x33, 0xF6                 ; xor si, si
    db      0x33, 0xFF                 ; xor di, di
    rep     movsw
    mov     ax, 0x1414
    call    near 0x8DCF
    db      0x86, 0xC4                 ; xchg ah, al
    and     ah, 0xFD
    or      ah, 0x01
    call    near 0x8DDC
    pop     ds
    pop     es
    ret

bios_ali_register_12_prepare:
    mov     ax, 0x1212
    call    near 0x8DCF
    and     al, 0xFB
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    mov     al, 0x42
    call    near 0xEE94
    test    al, 0x04
    jnz     short bios_ali_register_12_weighted
    JMP_ABS 0x2536
bios_ali_register_12_weighted:
    lea     si, [0x2088]
    db      0x8B, 0xFE                 ; mov di, si
    db      0x33, 0xD2                 ; xor dx, dx
    mov     ax, 0x1110
    call    near 0x8DCF
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DCF
    db      0x8B, 0xD8                 ; mov bx, ax
    and     ax, 0x0F0F
    and     bx, 0xF0F0
    db      0x8B, 0xD0                 ; mov dx, ax
    cmp     ah, 0x0F
    mov     ah, 0x00
    je      near bios_ali_weight_bh
    shr     dx, 8
    db      0x03, 0xF2                 ; add si, dx
    mov     ah, [cs:si]
    db      0x33, 0xD2                 ; xor dx, dx
    db      0x8B, 0xF7                 ; mov si, di
bios_ali_weight_bh:
    db      0x8B, 0xD3                 ; mov dx, bx
    cmp     bh, 0xF0
    mov     bh, 0x00
    je      near bios_ali_weight_al
    shr     dx, 12
    db      0x03, 0xF2                 ; add si, dx
    mov     bh, [cs:si]
    db      0x33, 0xD2                 ; xor dx, dx
    db      0x8B, 0xF7                 ; mov si, di
bios_ali_weight_al:
    db      0x02, 0xE7                 ; add ah, bh
    db      0x8A, 0xD0                 ; mov dl, al
    cmp     al, 0x0F
    mov     al, 0x00
    je      near bios_ali_weight_bl
    db      0x03, 0xF2                 ; add si, dx
    mov     al, [cs:si]
    db      0x33, 0xD2                 ; xor dx, dx
    db      0x8B, 0xF7                 ; mov si, di
bios_ali_weight_bl:
    db      0x8A, 0xD3                 ; mov dl, bl
    cmp     bl, 0xF0
    mov     bl, 0x00
    je      near bios_ali_weight_sum
    shr     dl, 4
    db      0x03, 0xF2                 ; add si, dx
    mov     bl, [cs:si]
bios_ali_weight_sum:
    db      0x02, 0xC3                 ; add al, bl
    db      0x02, 0xE0                 ; add ah, al
    mov     al, 0x15
    call    near 0x8DDC
    mov     ax, 0x1212
    call    near 0x8DCF
    or      al, 0x04
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    ret

%if ($ - rom_start) != 0x2537
    %error "Shadow-copy and CMOS weighted ALi helpers must end at 2537h"
%endif
; F000:2537h–2628h — AUTO Config ALi register consumers and row selector.
bios_autoconfig_write_reg20:
    call    near 0x25C4
    mov     si, 0x87B5
    db      0x03, 0xF0                 ; add si, ax
    mov     ax, 0x0202
    call    near 0x8DCF
    test    al, 0x08
    je      near bios_autoconfig_reg20_standard
    inc     si
    cs lodsw
    and     ah, 0x07
    jmp     short bios_autoconfig_reg20_merge
    nop
bios_autoconfig_reg20_standard:
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
bios_autoconfig_reg20_merge:
    db      0x8A, 0xFC                 ; mov bh, ah
    mov     ax, 0x2020
    call    near 0x8DCF
    and     al, 0xF8
    db      0x0A, 0xC7                 ; or al, bh
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    ret

bios_autoconfig_write_reg17:
    call    near 0x25C4
    mov     si, 0x87AD
    db      0x03, 0xF0                 ; add si, ax
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xFC                 ; mov bh, ah
    mov     ax, 0x1717
    call    near 0x8DCF
    and     al, 0x7C
    db      0x0A, 0xC7                 ; or al, bh
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    ret

bios_autoconfig_write_reg16:
    call    near 0x25C4
    mov     si, 0x87A9
    db      0x03, 0xF0                 ; add si, ax
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xFC                 ; mov bh, ah
    mov     ax, 0x1616
    call    near 0x8DCF
    and     al, 0xF0
    db      0x0A, 0xC7                 ; or al, bh
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    ret

bios_autoconfig_write_reg19:
    call    near 0x25C4
    mov     si, 0x87B1
    db      0x03, 0xF0                 ; add si, ax
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xFC                 ; mov bh, ah
    mov     ax, 0x1919
    call    near 0x8DCF
    and     al, 0x9F
    db      0x0A, 0xC7                 ; or al, bh
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    ret

; 25C4h — CMOS/BDA AUTO Config row selector; returns row offset in AX.
bios_autoconfig_row_offset:
    mov     ax, 0xB3B3
    call    near 0xEE94
    test    al, 0x04
    jnz     near bios_autoconfig_row_bda_plus6
    smsw    ax
    db      0x0A, 0xE4                 ; or ah, ah
    jnz     near bios_autoconfig_row_bda_plus6
    push    ds
    mov     bx, 0x0040
    mov     ds, bx
    mov     al, [0x00E2]
    pop     ds
    and     al, 0x07
    cmp     al, 0x05
    jne     near bios_autoconfig_row_multiply
    mov     ax, 0xB3B3
    call    near 0xEE94
    test    al, 0x02
    je      near bios_autoconfig_row_multiply
    mov     ax, 0x0007
    mov     cl, 0x14
    imul    cl
    jmp     short bios_autoconfig_row_return
    nop
bios_autoconfig_row_multiply:
    push    ds
    mov     bx, 0x0040
    mov     ds, bx
    mov     al, [0x00E2]
    pop     ds
    db      0x80, 0xE4, 0x00           ; and ah, 00h
    mov     cl, 0x14
    imul    cl
    jmp     short bios_autoconfig_row_return
    nop
bios_autoconfig_row_bda_plus6:
    push    ds
    mov     bx, 0x0040
    mov     ds, bx
    mov     al, [0x00E2]
    pop     ds
    db      0x80, 0xE4, 0x00           ; and ah, 00h
    add     al, 0x06
    mov     cl, 0x14
    imul    cl
bios_autoconfig_row_return:
    ret

%if ($ - rom_start) != 0x2629
    %error "AUTO Config row consumers and selector must end at 2629h"
%endif
; F000:2629h–26F8h — 16-bit segment sweep, temporary GDT and protected-mode copy.
bios_segment_sweep_7000:
    mov     dx, ds
    db      0x33, 0xDB                 ; xor bx, bx
    db      0x2B, 0xF6                 ; sub si, si
bios_segment_sweep_loop:
    mov     ds, bx
    mov     cx, 0x8000
    rep     lodsw
    db      0x2B, 0xF6                 ; sub si, si
    cmp     bx, 0x8000
    add     bx, 0x1000
    jne     short bios_segment_sweep_loop
    mov     ds, dx
    jmp     di

; GDT and pseudo-descriptor at F000:2646h. These are data, not linear code.
bios_temp_gdt:
    db      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
bios_temp_gdtr:
    db      0x40,0x00,0x46,0x26,0x0F,0x00
    db      0x00,0x00
    db      0xFF,0xFF,0x00,0x00,0x00,0x93,0x00,0x00
    db      0xFF,0xFF,0x00,0x80,0x83,0x93,0x00,0x03
    db      0xFF,0xFF,0x00,0x00,0xA3,0x93,0x00,0x03
    db      0xFF,0xFF,0x00,0x00,0x82,0x93,0x00,0x03
    db      0xFF,0xFF,0x00,0x00,0x84,0x93,0x00,0x03
    db      0xFF,0xFF,0x00,0x00,0x00,0x93,0x8F,0x00

bios_protected_mode_copy:
    mov     ecx, 0x00040000
    mov     esi, 0x00100000
    lgdt    [cs:0x264E]
    mov     eax, cr0
    or      al, 0x01
    mov     cr0, eax
    jmp     short $+2
    mov     ax, 0x0038
    mov     es, ax
    cld
    db      0xF3,0x67,0x66,0x26,0xAD  ; rep a32 es: lodsd
    mov     ax, 0x0010
    mov     es, ax
    mov     eax, cr0
    and     al, 0xFE
    mov     cr0, eax
    jmp     short $+2
    jmp     di

bios_segment_sweep_4000:
    mov     ax, 0x4000
bios_segment_sweep_4000_next:
    mov     ds, ax
    db      0x33, 0xF6                 ; xor si, si
    mov     cx, 0x8000
    rep     lodsw
    mov     ax, ds
    add     ah, 0x08
    cmp     ah, 0xA0
    jne     short bios_segment_sweep_4000_next
    jmp     di

bios_segment_sweep_0700:
    push    ds
    push    si
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ax, 0x0700
    mov     ds, ax
    mov     bx, 0x0002
bios_segment_sweep_0700_loop:
    db      0x33, 0xF6                 ; xor si, si
    mov     cx, 0x8000
    rep     lodsw
    mov     ax, ds
    add     ax, 0x1000
    mov     ds, ax
    dec     bx
    cmp     bl, 0x00
    jne     short bios_segment_sweep_0700_loop
    pop     si
    pop     ds
    ret

%if ($ - rom_start) != 0x26F9
    %error "Segment sweeps and temporary GDT must end at 26F9h"
%endif
; F000:26F9h–284Fh — chipset memory-window test and extended-address RAM probe.
bios_post_memory_window_test:
    cli
    db      0x2E,0xA0,0x18,0xB5        ; mov al,[cs:B518h]
    call    near 0x8300
    jne     short bios_post_memory_window_restore
    JMP_ABS 0x284F
bios_post_memory_window_restore:
    push    ds
    push    es
    push    word [0x0067]
    push    word [0x0069]
    mov     [0x0067], sp
    db      0x8C,0x16,0x69,0x00       ; mov [0069h], ss
    mov     ax, cs
    mov     ss, ax
    mov     di, 0x2722
    JMP_ABS 0x8CB2
bios_post_memreg_19:
    mov     ax, 0x1919
    mov     di, 0x272B
    JMP_ABS 0x8DED
    or      al, 0x03
    db      0x86, 0xE0                 ; xchg al, ah
    mov     di, 0x2735
    JMP_ABS 0x8DFB
bios_post_memreg_18:
    mov     ax, 0x1818
    mov     di, 0x273E
    JMP_ABS 0x8DED
    or      al, 0x02
    db      0x86, 0xE0                 ; xchg al, ah
    mov     di, 0x2748
    JMP_ABS 0x8DFB
bios_post_memreg_enter_pm:
    mov     di, 0x274E
    JMP_ABS 0x2686
bios_post_memreg_19_second:
    mov     ax, 0x1919
    mov     di, 0x2757
    JMP_ABS 0x8DED
    and     al, 0xFC
    db      0x86, 0xE0                 ; xchg al, ah
    mov     di, 0x2761
    JMP_ABS 0x8DFB

bios_extended_memory_probe:
    mov     ax, 0x1000
    mov     ds, ax
    mov     cx, 0x0002
    db      0x66,0x33,0xF6            ; xor esi, esi
    db      0x66,0xB8,0xAA,0x55,0xAA,0x55 ; mov eax,55AA55AAh
bios_extended_memory_probe_loop:
    db      0x67,0x66,0x8B,0x1E       ; mov ebx,[esi]
    db      0x67,0x66,0x89,0x06       ; mov [esi],eax
    jmp     short $+2
    db      0x67,0x66,0x8B,0x5E,0x04 ; mov ebx,[esi+4]
    db      0x67,0x66,0x89,0x46,0x04 ; mov [esi+4],eax
    jmp     short $+2
    db      0x67,0x66,0x8B,0x9E,0x00,0x08,0x00,0x00 ; mov ebx,[esi+0800h]
    db      0x67,0x66,0x8B,0x9E,0x00,0x10,0x00,0x00 ; mov ebx,[esi+1000h]
    db      0x67,0x66,0x8B,0x9E,0x00,0x18,0x00,0x00 ; mov ebx,[esi+1800h]
    db      0x67,0x66,0x8B,0x9E,0x00,0x20,0x00,0x00 ; mov ebx,[esi+2000h]
    db      0x67,0x66,0x3B,0x06       ; cmp eax,[esi]
    jne     near bios_extended_memory_probe_failed
    db      0x66,0x83,0xC6,0x04       ; add esi,4
    loop    bios_extended_memory_probe_loop
bios_extended_memory_probe_failed:
    db      0x0B,0xC9                 ; or cx,cx
    jne     near bios_extended_memory_probe_bad
    mov     ax, 0x1000
bios_extended_memory_probe_load_segment:
    mov     ds, ax
    mov     es, ax
    nop
    mov     sp, 0x27CA
    JMP_ABS 0x29BB
    dw      0x27CC
    je      near bios_extended_memory_probe_next_segment
bios_extended_memory_probe_bad:
    or      bp, 0x4000
    mov     sp, 0x27DA
    JMP_ABS 0x8D83
    dw      0x27DC
    jmp     short bios_extended_memory_probe_restore
bios_extended_memory_probe_next_segment:
    mov     ax, ds
    add     ax, 0x0400
    cmp     ax, 0x9000
    jne     short bios_extended_memory_probe_load_segment
    mov     ax, 0xB3B3
    nop
    mov     sp, 0x27F2
    JMP_ABS 0xEE94
    dw      0x27F4
    or      al, 0x01
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0x27FE
    JMP_ABS 0xEE9D
    dw      0x2800
bios_extended_memory_probe_restore:
    mov     ax, 0x1919
    nop
    mov     sp, 0x280A
    JMP_ABS 0x8DCF
    dw      0x280C
    or      al, 0x03
    db      0x86, 0xE0                 ; xchg al, ah
    mov     sp, 0x2816
    JMP_ABS 0x8DDC
    dw      0x2818
    mov     di, 0x281E
    JMP_ABS 0x2686
bios_extended_memory_probe_finish:
    mov     ax, 0x1919
    nop
    mov     sp, 0x2828
    JMP_ABS 0x8DCF
    dw      0x282A
    and     al, 0xFC
    db      0x86, 0xE0                 ; xchg al, ah
    mov     sp, 0x2834
    JMP_ABS 0x8DDC
    dw      0x2836
    mov     ax, 0x0040
    mov     ds, ax
    out     0x80, al
    db      0x8E,0x16,0x69,0x00       ; mov ss,[0069h]
    db      0x8B,0x26,0x67,0x00       ; mov sp,[0067h]
    db      0x8F,0x06,0x69,0x00       ; pop word [0069h]
    db      0x8F,0x06,0x67,0x00       ; pop word [0067h]
    pop     es
    pop     ds
    ret

%if ($ - rom_start) != 0x2850
    %error "Extended memory probe and chipset restoration must end at 2850h"
%endif
; F000:2850h–29F5h — CMOS setup, segment-size measurement, PIT timing and RAM test.
bios_post_memory_chipset_config:
    mov     ax, 0xC503
    call    near 0x8DDC
    mov     di, 0x285C
    JMP_ABS 0x8CB2
bios_post_memory_chipset_config_19:
    mov     ax, 0x1919
    mov     di, 0x2865
    JMP_ABS 0x8DED
    or      al, 0x03
    db      0x86, 0xE0                 ; xchg al, ah
    mov     di, 0x286F
    JMP_ABS 0x8DFB
bios_post_memory_chipset_config_18:
    mov     ax, 0x4318
    mov     di, 0x2878
    JMP_ABS 0x8DFB
bios_post_memory_chipset_config_pm:
    mov     di, 0x287E
    JMP_ABS 0x2686
bios_post_memory_chipset_config_19_second:
    mov     ax, 0x1919
    out     0x80, al
    mov     di, 0x2889
    JMP_ABS 0x8DED
    and     al, 0xFC
    db      0x86, 0xE0                 ; xchg al, ah
    mov     di, 0x2893
    JMP_ABS 0x8DFB
bios_post_memory_type_map:
    call    near 0x28F2
    cmp     al, 0x70
    jne     near bios_post_memory_type_60
    mov     bl, 0x70
    jmp     short bios_post_memory_type_apply
    nop
bios_post_memory_type_60:
    cmp     al, 0x60
    jne     near bios_post_memory_type_50
    mov     bl, 0x30
    jmp     short bios_post_memory_type_apply
    nop
bios_post_memory_type_50:
    cmp     al, 0x50
    jne     near bios_post_memory_type_40
    mov     bl, 0x50
    jmp     short bios_post_memory_type_apply
    nop
bios_post_memory_type_40:
    cmp     al, 0x40
    jne     near bios_post_memory_type_30
    mov     bl, 0x10
    jmp     short bios_post_memory_type_apply
    nop
bios_post_memory_type_30:
    cmp     al, 0x30
    jne     near bios_post_memory_type_20
    mov     bl, 0x40
    jmp     short bios_post_memory_type_apply
    nop
bios_post_memory_type_20:
    cmp     al, 0x20
    jne     near bios_post_memory_type_unknown
    mov     bl, 0x00
    jmp     short bios_post_memory_type_apply
    nop
bios_post_memory_type_unknown:
    call    near 0x8D83
    ret
bios_post_memory_type_apply:
    mov     di, 0x28E2
    JMP_ABS 0x26BE
bios_post_memory_type_write:
    mov     ax, 0x1818
    call    near 0x8DCF
    and     al, 0x8D
    db      0x0A, 0xC3                 ; or al, bl
    db      0x86, 0xE0                 ; xchg al, ah
    call    near 0x8DDC
    ret

; 28F2h — measure installed memory by scanning 16-KiB segments.
bios_memory_segment_measure:
    cli
    mov     ax, 0x9C00
bios_memory_segment_measure_loop:
    mov     ds, ax
    db      0x33, 0xF6                 ; xor si, si
    mov     cx, 0x2000
    rep     lodsw
    mov     ax, ds
    sub     ah, 0x04
    cmp     ah, 0x1C
    jae     short bios_memory_segment_measure_loop
    mov     ds, ax
    mov     di, 0x2911
    jmp     short bios_pit_measure_elapsed
    nop
bios_memory_segment_timer:
    db      0x8B, 0xD3                 ; mov dx, bx
    db      0x33, 0xED                 ; xor bp, bp
bios_memory_segment_timer_loop:
    mov     di, 0x291B
    jmp     short bios_pit_measure_elapsed
    nop
bios_memory_segment_pit:
    db      0x2B, 0xDA                 ; sub bx, dx
    jns     near bios_memory_segment_positive
    neg     bx
bios_memory_segment_positive:
    cmp     bh, 0x01
    jb      near bios_memory_segment_complete
    inc     bp
    mov     ax, ds
    add     ah, 0x04
    cmp     ah, 0xA0
    mov     ds, ax
    jne     short bios_memory_segment_timer_loop
bios_memory_segment_complete:
    db      0x8B, 0xDD                 ; mov bx, bp
    db      0x8B, 0xEC                 ; mov bp, sp
    db      0x8B, 0xC3                 ; mov ax, bx
    out     0x81, al
    cmp     bx, 0x20
    jbe     near bios_memory_segment_banks_ready
    mov     bx, 0x0040
bios_memory_segment_banks_ready:
    mov     cx, 0x0008
bios_memory_segment_bank_loop:
    shl     bl, 1
    jb      near bios_memory_segment_bank_done
    loop    bios_memory_segment_bank_loop
bios_memory_segment_bank_done:
    and     cl, 0x07
    db      0x8A, 0xE1                 ; mov ah, cl
    mov     cl, 0x04
    shl     ah, cl
    push    ds
    mov     bx, 0x0040
    mov     ds, bx
    db      0x8A, 0xC4                 ; mov al, ah
    mov     [0x00E0], ah
    pop     ds
    ret

; 296Bh — PIT channel-0 latch/read timing helper; returns elapsed count in BX.
bios_pit_measure_elapsed:
    db      0x33, 0xF6                 ; xor si, si
    mov     cx, 0x2000
    mov     al, 0x00
    out     0x43, al
    jmp     short $+2
    jmp     short $+2
    in      al, 0x40
    db      0x8A, 0xD8                 ; mov bl, al
    jmp     short $+2
    in      al, 0x40
    db      0x8A, 0xF8                 ; mov bh, al
    rep     lodsw
    mov     al, 0x00
    out     0x43, al
    jmp     short $+2
    jmp     short $+2
    in      al, 0x40
    db      0x8A, 0xE0                 ; mov ah, al
    jmp     short $+2
    in      al, 0x40
    db      0x86, 0xC4                 ; xchg ah, al
    db      0x2B, 0xD8                 ; sub bx, ax
    jmp     di

; 299Ah — read/clear the 512-KiB window in eight 64-KiB segment passes.
bios_memory_clear_1000:
    push    ds
    push    si
    mov     ax, 0x1000
    mov     ds, ax
    mov     bx, 0x0008
bios_memory_clear_1000_loop:
    db      0x33, 0xF6                 ; xor si, si
    mov     cx, 0x8000
    rep     lodsw
    mov     ax, ds
    add     ax, 0x1000
    mov     ds, ax
    dec     bx
    cmp     bl, 0x00
    jne     short bios_memory_clear_1000_loop
    pop     si
    pop     ds
    ret

; 29BBh — 32-bit memory pattern test, word fill/scan, and clear.
bios_ram_pattern_test:
    db      0x33, 0xF6                 ; xor si, si
    mov     cx, 0x2000
    db      0xF3,0x66,0xAD             ; rep o32 lodsd
    mov     ax, 0x55AA
bios_ram_pattern_test_repeat:
    mov     cx, 0x2000
    db      0x33, 0xFF                 ; xor di, di
    rep     stosw
    mov     cx, 0x2000
    db      0x33, 0xFF                 ; xor di, di
    rep     scasw
    jne     near bios_ram_pattern_test_failed
    not     ax
    cmp     ax, 0x55AA
    jne     short bios_ram_pattern_test_repeat
bios_ram_pattern_test_failed:
    mov     ax, 0x0000
    mov     di, 0x0000
    mov     cx, 0x2000
    rep     stosw
    ret

bios_memory_test_return:
    jmp     di
bios_cmos_read_b6:
    mov     ax, 0xB6B6
    call    near 0xEE94
    test    al, 0x01
    ret

%if ($ - rom_start) != 0x29F6
    %error "Memory measurement, PIT and RAM test helpers must end at 29F6h"
%endif
; F000:29F6h–2AC1h — chipset/CMOS flag merge and seven-entry far-handler table.
bios_chipset_cmos_merge:
    push    es
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     bl, [0xE036]
    and     byte [0xE036], 0xFE
    and     byte [0xE066], 0x00
    db      0x0A, 0xC0                 ; or al, al
    jne     near bios_chipset_cmos_nonzero
    test    bl, 0x01
    je      near bios_chipset_cmos_no_flag
    or      byte [0xE066], 0x01
    jmp     short bios_chipset_cmos_read_flags
    nop
bios_chipset_cmos_or_flag:
    or      byte [0xE036], 0x01
    mov     ax, 0xB571
    JMP_ABS 0x2AAF
bios_chipset_cmos_no_flag:
    mov     ax, 0xB568
    JMP_ABS 0x2AAF
bios_chipset_cmos_nonzero:
    db      0x02, 0xC3                 ; add al, bl
    and     al, 0x01
    db      0x08, 0x06, 0x36, 0xE0    ; or [E036h], al
bios_chipset_cmos_read_flags:
    push    ds
    mov     ax, 0x0040
    mov     ds, ax
    mov     si, 0x87A9
    db      0x03, 0x36, 0xE6, 0x00    ; add si, [ds:00E6h]
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xFC                 ; mov bh, ah
    add     si, 0x02
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xDC                 ; mov bl, ah
    add     si, 0x02
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xF4                 ; mov dh, ah
    add     si, 0x02
    mov     ax, 0x0202
    call    near 0x8DCF
    test    al, 0x08
    je      near bios_chipset_cmos_mask_standard
    inc     si
    cs lodsw
    and     ah, 0x07
    db      0x8A, 0xD4                 ; mov dl, ah
    jmp     short bios_chipset_cmos_mask_ready
    nop
bios_chipset_cmos_mask_standard:
    cs lodsw
    db      0x22, 0xE0                 ; and ah, al
    db      0x8A, 0xD4                 ; mov dl, ah
bios_chipset_cmos_mask_ready:
    pop     ds
    and     byte [0xE046], 0xF0
    and     byte [0xE047], 0x7C
    and     byte [0xE049], 0x9F
    and     byte [0xE050], 0xF8
    db      0x08, 0x3E, 0x46, 0xE0    ; or [E046h], bh
    db      0x08, 0x1E, 0x47, 0xE0    ; or [E047h], bl
    db      0x08, 0x36, 0x49, 0xE0    ; or [E049h], dh
    db      0x08, 0x16, 0x50, 0xE0    ; or [E050h], dl
    db      0x33, 0xC0                 ; xor ax, ax
    test    byte [0xE066], 0x01
    je      near bios_chipset_cmos_return
    JMP_ABS 0x2A1E
bios_chipset_cmos_return:
    pop     di
    pop     si
    pop     es
    retf

; Inline far-handler offset table consumed by the dispatcher above.
bios_chipset_cmos_far_handlers:
    dw      0xB62D, 0xB65C, 0xB664, 0xB66C
    dw      0xB674, 0xB67C, 0xB685
bios_chipset_cmos_next_entry:
    push    si

%if ($ - rom_start) != 0x2AC2
    %error "Chipset CMOS merge routine and handler table must end at 2AC2h"
%endif
; F000:2AC2h–2B12h — CMOS-selected far-handler lookup and index normalization.
bios_chipset_cmos_select_handler:
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2AB3
    mov     bl, [0xE050]
    test    byte [0xE036], 0x01
    je      near bios_chipset_cmos_select_normalize
    and     bl, 0x07
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_chipset_cmos_select_return
    nop
bios_chipset_cmos_select_normalize:
    and     byte [0xE050], 0xF8
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x07
    cmp     bl, 0x07
    jne     near bios_chipset_cmos_select_store
    mov     bl, 0x06
    cmp     al, 0x80
    ja      near bios_chipset_cmos_select_store
    mov     bl, 0x00
bios_chipset_cmos_select_store:
    db      0x08, 0x1E, 0x50, 0xE0    ; or [E050h], bl
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_chipset_cmos_select_return:
    pop     di
    pop     si
    retf

; Far-handler offset table at 2B0Bh.
bios_chipset_cmos_select_table:
    dw      0xB5FF, 0xB604, 0xB60B, 0xB610

%if ($ - rom_start) != 0x2B13
    %error "CMOS-selected far-handler lookup must end at 2B13h"
%endif
; F000:2B13h–2C68h — CMOS-indexed selectors for E046h and E049h fields.
bios_cmos_e046_low_selector:
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2B0B
    mov     bl, [0xE046]
    test    byte [0xE036], 0x01
    je      near bios_cmos_e046_low_normalize
    and     bl, 0x03
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_cmos_e046_low_return
    nop
bios_cmos_e046_low_normalize:
    and     byte [0xE046], 0xFC
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x03
    db      0x08, 0x1E, 0x46, 0xE0    ; or [E046h], bl
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_cmos_e046_low_return:
    pop     di
    pop     si
    retf

bios_cmos_e046_high_selector:
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2B0B
    mov     bl, [0xE046]
    test    byte [0xE036], 0x01
    je      near bios_cmos_e046_high_normalize
    and     bl, 0x0C
    shr     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_cmos_e046_high_return
    nop
bios_cmos_e046_high_normalize:
    and     byte [0xE046], 0xF3
    shr     bl, 2
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x03
    db      0x8A, 0xC3                 ; mov al, bl
    shl     al, 2
    db      0x08, 0x06, 0x46, 0xE0    ; or [E046h], al
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_cmos_e046_high_return:
    pop     di
    pop     si
    retf

; Two CMOS handler offsets used by the E049h bit selectors.
bios_cmos_e049_table:
    dw      0xB6D3, 0xB6D8

bios_cmos_e049_bit6_selector:
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2B8D
    mov     bl, [0xE049]
    test    byte [0xE036], 0x01
    je      near bios_cmos_e049_bit6_normalize
    and     bl, 0x40
    shr     bl, 5
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_cmos_e049_bit6_return
    nop
bios_cmos_e049_bit6_normalize:
    and     byte [0xE049], 0xBF
    shr     bl, 6
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x01
    db      0x8A, 0xC3                 ; mov al, bl
    shl     al, 6
    db      0x08, 0x06, 0x49, 0xE0    ; or [E049h], al
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_cmos_e049_bit6_return:
    pop     di
    pop     si
    retf

bios_cmos_e049_bit5_selector:
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2B8D
    mov     bl, [0xE049]
    test    byte [0xE036], 0x01
    je      near bios_cmos_e049_bit5_normalize
    and     bl, 0x20
    shr     bl, 4
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_cmos_e049_bit5_return
    nop
bios_cmos_e049_bit5_normalize:
    and     byte [0xE049], 0xDF
    shr     bl, 5
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x01
    db      0x8A, 0xC3                 ; mov al, bl
    shl     al, 5
    db      0x08, 0x06, 0x49, 0xE0    ; or [E049h], al
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_cmos_e049_bit5_return:
    pop     di
    pop     si
    retf

; Four handler offsets for the E047h low two-bit selector.
bios_cmos_e047_table:
    dw      0xB55F, 0xB60B, 0xB604, 0xB5FF

bios_cmos_e047_low_selector:
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2C15
    mov     bl, [0xE047]
    test    byte [0xE036], 0x01
    je      near bios_cmos_e047_low_normalize
    and     bl, 0x03
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_cmos_e047_low_return
    nop
bios_cmos_e047_low_normalize:
    and     byte [0xE047], 0xFC
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x03
    cmp     bl, 0x00
    jne     near bios_cmos_e047_low_store
    mov     bl, 0x03
    cmp     al, 0x80
    ja      near bios_cmos_e047_low_store
    mov     bl, 0x01
bios_cmos_e047_low_store:
    db      0x08, 0x1E, 0x47, 0xE0    ; or [E047h], bl
    db      0x8A, 0xD3                 ; mov dl, bl
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_cmos_e047_low_return:
    pop     di
    pop     si
    retf

%if ($ - rom_start) != 0x2C69
    %error "CMOS E046/E049/E047 selector handlers must end at 2C69h"
%endif
; F000:2C69h–2D10h — Enabled/Disabled field and sixteen-value timing selector.
bios_cmos_e042_enable_selector:
    push    si
    push    di
    mov     bl, [0xE042]
    db      0x0A, 0xC0                 ; or al, al
    jne     near bios_cmos_e042_enable_nonzero
    or      byte [0xE042], 0x20
    mov     si, 0xB571
    test    bl, 0x20
    jne     near bios_cmos_e042_enable_selected
    and     byte [0xE042], 0x1F
    mov     si, 0xB568
bios_cmos_e042_enable_selected:
    db      0x8B, 0xC6                 ; mov ax, si
    jmp     short bios_cmos_e042_enable_return
    nop
bios_cmos_e042_enable_nonzero:
    shr     bl, 5
    db      0x02, 0xC3                 ; add al, bl
    and     al, 0x01
    je      near bios_cmos_e042_enable_clear
    or      byte [0xE042], 0x20
    jmp     short bios_cmos_e042_enable_return
    nop
bios_cmos_e042_enable_clear:
    and     byte [0xE042], 0x1F
    mov     ax, 0x0000
bios_cmos_e042_enable_return:
    pop     di
    pop     si
    retf

; Sixteen timing-label offsets selected by the high nibble of BDA E052h.
bios_cmos_e052_timing_table:
    dw      0xB6FB, 0xB700, 0xB708, 0xB70F
    dw      0xB717, 0xB71C, 0xB724, 0xB729
    dw      0xB731, 0xB736, 0xB73E, 0xB745
    dw      0xB74D, 0xB752, 0xB75A, 0xB761

bios_cmos_e052_timing_selector:
    push    si
    push    di
    db      0x33, 0xDB                 ; xor bx, bx
    mov     si, 0x2CAF
    mov     bl, [0xE052]
    test    byte [0xE052], 0x01
    jne     near bios_cmos_e052_timing_update
    and     bl, 0xF0
    shr     bl, 3
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
    jmp     short bios_cmos_e052_timing_return
    nop
bios_cmos_e052_timing_update:
    and     byte [0xE052], 0x0F
    shr     bl, 4
    db      0x02, 0xD8                 ; add bl, al
    and     bl, 0x0F
    db      0x8A, 0xC3                 ; mov al, bl
    shl     al, 4
    db      0x08, 0x06, 0x52, 0xE0    ; or [E052h], al
    shl     bl, 1
    db      0x03, 0xF3                 ; add si, bx
    mov     ax, [cs:si]
bios_cmos_e052_timing_return:
    pop     di
    pop     si
    retf

%if ($ - rom_start) != 0x2D11
    %error "CMOS E042/E052 selectors must end at 2D11h"
%endif
; F000:2D11h–2DF4h — memory-pattern benchmark and PIT-calibrated divisor selector.
; The block is fully transcribed; its external entry provenance remains unresolved.
bios_memory_benchmark_entry:
    add     byte [0xFA06], bl
    mov     ax, 0x1000
    mov     es, ax
    mov     di, 0x0000
    mov     ax, 0xF3F7
    push    ax
    cld
    mov     cx, 0x03E8
    rep     stosw
    mov     al, 0xCB
    stosb
    pop     ax
    dec     ax
    mov     di, 0x0800
    cld
    mov     cx, 0x03E8
    rep     stosw
    mov     al, 0xCB
    stosb
    mov     ax, es
    mov     ds, ax
    call    near bios_pit_measurement
    mov     di, 0xF000
    mov     cx, 0x0028
bios_memory_benchmark_fill_loop:
    push    cx
    push    di
    call    near bios_pit_measurement
    pop     di
    stosw
    pop     cx
    loop    bios_memory_benchmark_fill_loop

    mov     si, 0xF000
    mov     cx, 0x0028
    push    cx
    db      0x2B, 0xC0                 ; sub ax, ax
    db      0x2B, 0xD2                 ; sub dx, dx
bios_memory_benchmark_average_loop:
    add     ax, [si]
    adc     dx, 0x0000
    add     si, 0x0002
    loop    bios_memory_benchmark_average_loop
    pop     cx
    div     cx
    db      0x8B, 0xC8                 ; mov cx, ax
    mov     [0xF800], ax
    mov     dx, 0x000E
    mov     ax, 0x236E
    div     cx

    mov     bx, 0x0004
    cmp     ax, 0x01C2
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0005
    cmp     ax, 0x0226
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0006
    cmp     ax, 0x02BC
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0008
    cmp     ax, 0x0384
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x000A
    cmp     ax, 0x044C
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x000C
    cmp     ax, 0x0578
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0010
    cmp     ax, 0x0640
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0010
    cmp     ax, 0x0708
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0014
    cmp     ax, 0x08CA
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0019
    cmp     ax, 0x0ABE
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0021
    cmp     ax, 0x0E2E
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0028
    cmp     ax, 0x1130
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0032
    cmp     ax, 0x15E0
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0042
    cmp     ax, 0x1BBC
    jbe     short bios_memory_benchmark_class_ready
    mov     bx, 0x0050
bios_memory_benchmark_class_ready:
    db      0x33, 0xFF                 ; xor di, di
    mov     cx, 0x8000
    db      0x33, 0xC0                 ; xor ax, ax
    rep     stosw
    db      0x8B, 0xC3                 ; mov ax, bx
    pop     es
    pop     ds
    ret

; F000:2DF5h–2E72h — PIT channel-2 measurement, counter read and setup.
bios_pit_measurement:
    cli
    in      al, 0x61
    mov     [0xF804], al
    call    near 0x2E58
    mov     bx, 0xFFFF
    mov     al, [0xF804]
    or      al, 0x01
    out     0x61, al
    jmp     short $+2
    db      0x9A,0x00,0x00,0x00,0x10 ; call far 1000:0000
    mov     al, [0xF804]
    and     al, 0xFC
    out     0x61, al
    jmp     short $+2
    call    near 0x2E49
    mov     [0xF800], ax
    in      al, 0x61
    mov     [0xF804], al
    call    near 0x2E58
    mov     bx, 0xFFFF
    mov     al, [0xF804]
    or      al, 0x01
    out     0x61, al
    db      0x9A,0x00,0x08,0x00,0x10 ; call far 1000:0800
    mov     al, [0xF804]
    and     al, 0xFC
    out     0x61, al
    jmp     short $+2
    call    near 0x2E49
    sub     word [0xF800], ax
    mov     ax, [0xF800]
    ret

bios_pit_read_channel2:
    in      al, 0x42
    jmp     short $+2
    db      0x8A, 0xE0                 ; mov ah, al
    in      al, 0x42
    jmp     short $+2
    db      0x86, 0xE0                 ; xchg ah, al
    neg     ax
    ret

bios_pit_channel2_setup:
    in      al, 0x61
    and     al, 0xFC
    out     0x61, al
    jmp     short $+2
    mov     al, 0xB4
    out     0x43, al
    jmp     short $+2
    db      0x2A, 0xC0                 ; sub al, al
    out     0x42, al
    jmp     short $+2
    jmp     short $+2
    out     0x42, al
    jmp     short $+2
    ret

%if ($ - rom_start) != 0x2E73
    %error "PIT channel-2 measurement helpers must end at 2E73h"
%endif
; 2E73h and 2EF1h are zero bytes with no confirmed entry/reference.
    db      0x00
%if ($ - rom_start) != 0x2E74
    %error "B513 selector handler must begin at 2E74h"
%endif

; B7B2 table handler: CMOS B513h selector and E000h working-image bit merge.
bios_cmos_b513_selector_handler:
    push    ax
    db      0x33, 0xFF                 ; xor di, di
    smsw    ax
    db      0x0A, 0xE4                 ; or ah, ah
    je      short bios_cmos_b513_mode_ready
    db      0xF7, 0xD7                 ; not di
bios_cmos_b513_mode_ready:
    mov     al, [cs:0xB513]
    call    near 0x83AE
    db      0x8B, 0xF0                 ; mov si, ax
    and     si, 0x7F
    pop     bx
    db      0x8A, 0xFC                 ; mov bh, ah
    mov     ax, cs
    db      0x0B, 0xFF                 ; or di, di
    jne     short bios_cmos_b513_merge_done
    cmp     ax, 0xF000
    jne     short bios_cmos_b513_merge_done
    db      0x08, 0xBC, 0x00, 0xE0    ; or byte [si+E000h], bh
bios_cmos_b513_merge_done:
    db      0x0A, 0xDB                 ; or bl, bl
    je      short bios_cmos_b513_empty_path
    db      0x0B, 0xFF                 ; or di, di
    jne     short bios_cmos_b513_alt_path
    cmp     ax, 0xF000
    je      short bios_cmos_b513_rom_path
bios_cmos_b513_alt_path:
    JMP_ABS 0x8734
bios_cmos_b513_rom_path:
    JMP_ABS 0x8738
bios_cmos_b513_empty_path:
    JMP_ABS 0x8727

%if ($ - rom_start) != 0x2EB4
    %error "B513 selector handler must end at 2EB4h"
%endif

; B7B4 table handler: CMOS B519h selector and E000h working-image bit clear.
bios_cmos_b519_selector_handler:
    push    ax
    db      0x33, 0xFF                 ; xor di, di
    smsw    ax
    db      0x0A, 0xE4                 ; or ah, ah
    je      short bios_cmos_b519_mode_ready
    db      0xF7, 0xD7                 ; not di
bios_cmos_b519_mode_ready:
    mov     al, [cs:0xB519]
    call    near 0x83AE
    db      0x8B, 0xF0                 ; mov si, ax
    and     si, 0x7F
    pop     bx
    db      0x8A, 0xFC                 ; mov bh, ah
    mov     ax, cs
    db      0x0B, 0xFF                 ; or di, di
    je      short bios_cmos_b519_merge_done
    cmp     ax, 0xF000
    jne     short bios_cmos_b519_merge_done
    db      0xF6, 0xD7                 ; not bh
    db      0x20, 0xBC, 0x00, 0xE0    ; and byte [si+E000h], bh
    db      0xF6, 0xD7                 ; not bh
bios_cmos_b519_merge_done:
    db      0x0A, 0xDB                 ; or bl, bl
    je      short bios_cmos_b513_empty_path
    db      0x0B, 0xFF                 ; or di, di
    je      short bios_cmos_b519_final_alt
    cmp     ax, 0xF000
    je      short bios_cmos_b513_rom_path
bios_cmos_b519_final_alt:
    jmp     short bios_cmos_b513_alt_path

%if ($ - rom_start) != 0x2EF1
    %error "B519 selector handler must end at 2EF1h"
%endif
    db      0x00

; F000:2EF2h–2F23h — Setup exit relocation handoff (direct caller F109h).
bios_setup_relocation_handoff:
    cld
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
    db      0x8C,0x16,0x69,0x04       ; mov [0469h], ss
    db      0x89,0x26,0x67,0x04       ; mov [0467h], sp
    mov     ax, 0x0100
    mov     es, ax
    mov     ds, ax
    cli
    mov     ss, ax
    mov     sp, 0xDFFE
    sti
    db      0x33, 0xF6                 ; xor si, si
    db      0x33, 0xFF                 ; xor di, di
    mov     cx, 0x7000
    db      0x2E,0xF3,0xA5            ; cs rep movsw
    mov     di, 0xE000
    mov     cx, 0x0FF1
    db      0x32, 0xC0                 ; xor al, al
    rep     stosb
    JMP_ABS 0x3C5E

%if ($ - rom_start) != 0x2F24
    %error "Setup relocation handoff must end at 2F24h"
%endif
; Setup exit prompt strings at 2F24h and 2F43h.
bios_setup_exit_save_prompt:
    db      "Write to CMOS and Exit (Y/N) ?", 0
bios_setup_exit_quit_prompt:
    db      "Want to Quit Without Saving (Y/N) ?", 0

%if ($ - rom_start) != 0x2F67
    %error "Setup exit prompt strings must end at 2F67h"
%endif

; F000:2F67 — Setup exit confirmation and saved-stack restoration.
bios_setup_exit_confirm:
    mov     bx, 0x2F24
    call    near 0x5959
    cmp     al, 0x59
    jne     short bios_setup_exit_return
    call    near 0x852F
    jmp     short bios_setup_exit_restore_stack
bios_setup_exit_quit_confirm:
    mov     bx, 0x2F43
    call    near 0x5959
    cmp     al, 0x59
    jne     short bios_setup_exit_return
bios_setup_exit_restore_stack:
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
    cli
    mov     ss, [0x0469]
    mov     sp, [0x0467]
    sti
bios_setup_exit_return:
    ret

%if ($ - rom_start) != 0x2F8F
    %error "Setup exit handler must end at 2F8Fh"
%endif

; F000:2F8F — clear the BIOS Data Area fields used by the temporary disk test.
bios_clear_disk_bda_fields:
    db      0x33, 0xC0                 ; xor ax, ax
    mov     di, 0x0442
    stosw
    stosw
    stosw
    stosb
    mov     di, 0x0474
    stosw
    stosb
    mov     di, 0x048C
    stosw
    stosb
    ret

%if ($ - rom_start) != 0x2FA3
    %error "BDA clear helper must end at 2FA3h"
%endif

; F000:2FA3 — temporary IVT substitution around INT 13h AH=14h.
bios_setup_temp_int13_test:
    push    si
    push    di
    push    ds
    push    ds
    pop     es
    mov     di, 0xE429
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
    mov     si, 0x0100
    movsw
    movsw
    mov     si, 0x004C
    movsw
    movsw
    mov     si, 0x0104
    movsw
    movsw
    mov     si, 0x0118
    movsw
    movsw
    push    ds
    pop     es
    cli
    mov     si, 0x004C
    mov     di, 0x0100
    mov     ax, 0xA08D
    db      0x87, 0x04                 ; xchg [si], ax
    stosw
    mov     ax, cs
    db      0x87, 0x44, 0x02           ; xchg [si+2], ax
    stosw
    call    near bios_clear_disk_bda_fields
    pop     ds
    push    ds
    cmp     byte [0xE421], 0x00
    pushf
    mov     ax, 0x0040
    mov     ds, ax
    inc     byte [0x0075]
    mov     di, 0x0104
    mov     dl, 0x80
    popf
    je      short bios_setup_temp_int13_slot_ready
    mov     di, 0x0118
    inc     byte [0x0075]
    inc     dl
bios_setup_temp_int13_slot_ready:
    mov     ax, 0xE411
    stosw
    mov     ax, 0x0100
    stosw
    sti
    mov     ah, 0x14
    int     0x13
    jae     short bios_setup_temp_int13_aaa3
    mov     al, 0x02
    jmp     short bios_setup_temp_int13_restore
bios_setup_temp_int13_aaa3:
    call    near 0xAAA3
    jae     short bios_setup_temp_int13_success
    mov     al, 0x03
    jmp     short bios_setup_temp_int13_restore
bios_setup_temp_int13_success:
    pop     ds
    call    near 0x691C
    push    ds
bios_setup_temp_int13_restore:
    push    ax
    db      0x33, 0xC0                 ; xor ax, ax
    mov     es, ax
    call    near bios_clear_disk_bda_fields
    cli
    mov     si, 0xE429
    mov     di, 0x0100
    movsw
    movsw
    mov     di, 0x004C
    movsw
    movsw
    mov     di, 0x0104
    movsw
    movsw
    mov     di, 0x0118
    movsw
    movsw
    sti
    pop     ax
    pop     ds
    pop     di
    pop     si
    ret

%if ($ - rom_start) != 0x3044
    %error "Temporary INT 13h path must end at 3044h"
%endif

incbin  "ami486.bin", ($ - rom_start), (0x3C5C - ($ - rom_start)) ; inherited strings/data from 3044h to 3C5Bh
    db      0x00, 0x00

%if ($ - rom_start) != 0x3C5E
    %error "Setup main menu must begin at 3C5Eh"
%endif

; F000:3C5E — BIOS Setup main menu and twelve-item dispatch loop.
bios_setup_main_menu:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0002
    call    near 0x84CB
    call    near 0x566B
    call    near 0x0995
    lea     bx, [0x345E]
    lea     ax, [0x3473]
    call    near bios_setup_menu_header
    mov     al, [0xE187]
    mov     [0xE189], al
    mov     al, [0xE188]
    mov     [0xE18A], al
    call    near bios_setup_menu_reset_selection
bios_setup_menu_loop:
    call    near 0x5AA2
    db      0x0B, 0xC0                 ; or ax, ax
    jne     short bios_setup_menu_key_ready
    lea     bx, [0x34AB]
    mov     ax, 0x0A28
    call    near 0x58A1
    lea     bx, [0x36DB]
    mov     ax, 0x0C28
    call    near 0x58A1
    call    near 0x5902
    call    near 0x2F80
bios_setup_menu_key_ready:
    mov     ax, 0x1200
    mov     dl, 0x50
    mov     bx, 0x2016
    call    near 0x5862
bios_setup_menu_draw_loop:
    mov     al, [0xE1A2]
    call    near bios_setup_menu_draw_selection
    mov     al, 0x01
    call    near bios_setup_menu_move
    cmp     byte [0xE187], 0x00
    jne     short bios_setup_menu_draw_loop
    mov     al, [0xE189]
    mov     [0xE187], al
    mov     al, [0xE18A]
    mov     [0xE188], al
bios_setup_menu_refresh:
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     ax, 0x1301
    mov     dx, 0x174E
    call    near 0x5802
    mov     al, [0xE187]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    shl     bx, 1
    mov     bx, [bx+0x342E]
    mov     ax, 0x1528
    call    near 0x58BE
    mov     al, [0xE1A3]
    call    near bios_setup_menu_draw_selection
    call    near 0x5902
    mov     [0xE182], ax
    mov     al, [0xE1A2]
    call    near bios_setup_menu_draw_selection
    mov     ax, [0xE182]
    db      0x2D, 0x0D, 0x00           ; sub ax, 000Dh
    je      short bios_setup_menu_warning
    db      0x2D, 0x0E, 0x00           ; sub ax, 000Eh
    je      short bios_setup_menu_exit_no_save
    sub     ax, 0x0121
    jb      short bios_setup_menu_refresh
    db      0x2D, 0x01, 0x00           ; sub ax, 0001h
    jbe     short bios_setup_menu_palette
    db      0x2D, 0x07, 0x00           ; sub ax, 0007h
    je      short bios_setup_menu_exit_save
    db      0x2D, 0x04, 0x00           ; sub ax, 0004h
    je      short bios_setup_menu_move_down
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_setup_menu_move_down
    dec     ax
    dec     ax
    je      short bios_setup_menu_move_up
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_setup_menu_move_up
    jmp     short bios_setup_menu_refresh
bios_setup_menu_move_down:
    mov     al, 0xFF
bios_setup_menu_move_apply:
    call    near bios_setup_menu_move
    jmp     short bios_setup_menu_refresh
bios_setup_menu_move_up:
    mov     al, 0x01
    jmp     short bios_setup_menu_move_apply
bios_setup_menu_warning:
    cmp     byte [0xE187], 0x04
    jg      short bios_setup_menu_dispatch
    call    near bios_setup_menu_warning_screen
    db      0x3D, 0x1B, 0x00           ; cmp ax, 001Bh
    jne     short bios_setup_menu_dispatch
    JMP_ABS 0x3C6D
bios_setup_menu_dispatch:
    mov     al, [0xE187]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    shl     bx, 1
    mov     ax, [bx+0x3446]
    mov     [bp-0x02], ax
    call    word [bp-0x02]
    JMP_ABS 0x3C6D
bios_setup_menu_exit_no_save:
    call    near 0x2F76
    JMP_ABS 0x3C6D
bios_setup_menu_palette:
    call    near 0x56AE
    JMP_ABS 0x3C6D
bios_setup_menu_exit_save:
    call    near 0x2F67
    JMP_ABS 0x3C6D

bios_setup_menu_draw_selection:
    mov     [0xE19F], al
    mov     al, [0xE187]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    shl     bx, 1
    mov     bx, [bx+0x318C]
    mov     ah, [0xE188]
    db      0x2A, 0xC0                 ; sub al, al
    add     ax, 0x0528
    call    near 0x58C6
    ret

bios_setup_menu_warning_screen:
    lea     bx, [0x34C1]
    lea     ax, [0x34D4]
    call    near bios_setup_menu_header
    mov     al, [0xE1A3]
    mov     [0xE19F], al
    mov     ax, 0x0603
    mov     dx, 0x144C
    call    near 0x5821
    lea     bx, [0x35DB]
    mov     ax, 0x1228
    call    near 0x58C6
    lea     bx, [0x3577]
    mov     ax, 0x0D16
    call    near 0x58D3
    lea     bx, [0x359F]
    mov     ax, 0x0E16
    call    near 0x58D3
    lea     bx, [0x35BE]
    mov     ax, 0x0F16
    call    near 0x58D3
    lea     bx, [0x34D5]
    mov     ax, 0x0828
    call    near 0x58BE
    lea     bx, [0x3501]
    mov     ax, 0x0A28
    call    near 0x58BE
    lea     bx, [0x354A]
    mov     ax, 0x0C28
    call    near 0x58BE
    call    near 0x5902
    ret

bios_setup_menu_move:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    push    ax
    db      0x00, 0x06, 0x88, 0xE1    ; add byte [0xE188], al
bios_setup_menu_move_delta:
    mov     al, [bp-0x02]
    db      0x00, 0x06, 0x87, 0xE1    ; add byte [0xE187], al
    jns     short bios_setup_menu_move_in_range
    call    near bios_setup_menu_move_to_last
    jmp     short bios_setup_menu_move_poll
bios_setup_menu_move_in_range:
    cmp     byte [0xE187], 0x0B
    jle     short bios_setup_menu_move_poll
    call    near bios_setup_menu_reset_selection
bios_setup_menu_move_poll:
    call    near 0x5AA2
    db      0x0B, 0xC0                 ; or ax, ax
    je      short bios_setup_menu_move_delta
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

bios_setup_menu_reset_selection:
    db      0x2A, 0xC0                 ; sub al, al
    mov     [0xE187], al
    mov     [0xE188], al
    ret

bios_setup_menu_move_to_last:
    call    near bios_setup_menu_reset_selection
    jmp     short bios_setup_menu_last_loop
bios_setup_menu_last_step:
    mov     al, 0x01
    call    near bios_setup_menu_move
bios_setup_menu_last_loop:
    cmp     byte [0xE187], 0x0B
    jne     short bios_setup_menu_last_step
    ret

%if ($ - rom_start) != 0x3E3F
    %error "Setup main-menu code must end at 3E3Fh"
%endif

; F000:3E3F — shared Setup menu/header renderer.
bios_setup_menu_header:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    push    ax
    push    bx
    mov     al, [0xE1A8]
    mov     [0xE19F], al
    db      0x2B, 0xC0                 ; sub ax, ax
    mov     dx, 0x184F
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x360C]
    mov     ax, 0x0112
    call    near 0x58AF
    mov     bx, [bp-0x04]
    mov     ax, 0x012A
    call    near 0x58AF
    lea     bx, [0x8018]
    mov     ax, 0x0228
    call    near 0x58C6
    mov     ax, 0x0300
    mov     dl, 0x50
    mov     bx, 0x2017
    call    near 0x5862
    mov     bx, [bp-0x02]
    mov     ax, 0x1828
    call    near bios_setup_menu_value_input
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x0401
    mov     dx, 0x174E
    call    near 0x5802
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x3E99
    %error "Setup header renderer must end at 3E99h"
%endif

; F000:3E99 — Setup value-input/parser routine.
bios_setup_menu_value_input:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0004
    push    bx
    push    di
    db      0x8B, 0xF8                 ; mov di, ax
    mov     al, [0xE1A8]
    mov     [0xE19F], al
    mov     [0xE1A0], al
    call    near 0x592A
    db      0x8B, 0xC8                 ; mov cx, ax
    add     ax, [bp-0x06]
    dec     ax
    mov     [bp-0x04], ax
    dec     cx
    shr     cx, 1
    db      0x03, 0xF9                 ; add di, cx
    jmp     short bios_setup_menu_value_input_loop_bound
bios_setup_menu_value_input_loop:
    mov     bx, [bp-0x04]
    dec     word [bp-0x04]
    mov     al, [bx]
    mov     [bp-0x01], al
    cmp     al, 0x3A
    jne     short bios_setup_menu_value_input_not_colon
    call    near 0x5891
    jmp     short bios_setup_menu_value_input_emit
bios_setup_menu_value_input_not_colon:
    cmp     byte [bp-0x01], 0x20
    jne     short bios_setup_menu_value_input_emit
    call    near 0x58B5
bios_setup_menu_value_input_emit:
    db      0x8B, 0xD7                 ; mov dx, di
    dec     di
    mov     al, [bp-0x01]
    call    near 0x58EE
bios_setup_menu_value_input_loop_bound:
    mov     ax, [bp-0x06]
    cmp     [bp-0x04], ax
    jae     short bios_setup_menu_value_input_loop
    pop     di
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x3EF2
    %error "Setup value-input parser must end at 3EF2h"
%endif

; F000:3EF2 — Setup metric/value formatter.
bios_setup_menu_metric_formatter:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0002
    push    bx
    push    di
    push    si
    mov     si, 0x0019
    call    near 0x592A
    db      0x8B, 0xF8                 ; mov di, ax
    db      0x3B, 0xFE                 ; cmp di, si
    jbe     short bios_setup_menu_metric_clamped
    db      0x8B, 0xF0                 ; mov si, ax
bios_setup_menu_metric_clamped:
    db      0x8B, 0xC6                 ; mov ax, si
    shr     ax, 1
    db      0x05, 0x03, 0x00           ; add ax, 0003h
    db      0x8B, 0xC8                 ; mov cx, ax
    sub     ax, 0x0A28
    neg     ax
    add     cx, 0x0E28
    mov     dl, [0xE1A6]
    mov     [0xE19F], dl
    db      0x8B, 0xD1                 ; mov dx, cx
    mov     bx, 0x0003
    call    near 0x578D
    mov     bx, [bp-0x04]
    mov     ax, 0x0B28
    call    near 0x58A1
    lea     bx, [0x36DB]
    mov     ax, 0x0D28
    call    near 0x58A1
    call    near 0xF571
    call    near 0x5902
    pop     si
    pop     di
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x3F4A
    %error "Setup menu/parser/formatter region must end at 3F4Ah"
%endif

; F000:3F4A–4230 — POST system-configuration display and helpers.
bios_post_system_config_entry:
    call    near bios_post_system_config_display
    mov     si, 0x45D8
    call    near bios_rom_print_si
    call    near 0x19FB
    ret

bios_post_system_config_alt_entry:
    call    near bios_rom_print_si
    call    near bios_post_newline
    ret

bios_rom_print_si:
    push    ax
    call    near 0xF52E
    pop     ax
    ret

bios_print_hex_byte:
    push    ax
    shr     al, 4
    call    near bios_print_hex_nibble
    pop     ax

bios_print_hex_nibble:
    and     al, 0x0F
    cmp     al, 0x0A
    jb      short bios_print_hex_emit
    add     al, 0x07
bios_print_hex_emit:
    add     al, 0x30
    mov     ah, 0x0E
    int     0x10
    ret

bios_post_system_config_display:
    mov     si, 0x4231
    call    near bios_rom_print_si
    mov     si, 0x431F
    call    near bios_rom_print_si
    call    near bios_post_cpu_info_select
    push    ax
    mov     si, 0x43AF
    call    near bios_rom_print_si
    push    ds
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
    mov     ax, [0x0467]
    pop     ds
    call    near bios_print_decimal
    call    near bios_post_kb_suffix
    mov     si, 0x4337
    call    near bios_rom_print_si
    pop     ax
    call    near bios_post_equipment_display
    mov     si, 0x43C7
    call    near bios_rom_print_si
    mov     ah, 0x88
    int     0x15
    call    near bios_print_decimal
    call    near bios_post_kb_suffix
    mov     si, 0x434F
    call    near bios_rom_print_si
    mov     al, 0x90
    call    near 0xEE94
    push    ax
    shr     al, 4
    call    near bios_post_cmos_option
    mov     si, 0x43DF
    call    near bios_rom_print_si
    mov     al, 0x92
    call    near 0xEE94
    push    ax
    shr     al, 4
    mov     ah, 0x99
    call    near bios_post_cmos_nibble
    call    near bios_post_newline
    mov     si, 0x4367
    call    near bios_rom_print_si
    pop     cx
    pop     ax
    push    cx
    call    near bios_post_cmos_option
    mov     si, 0x43F7
    call    near bios_rom_print_si
    pop     ax
    mov     ah, 0x9A
    call    near bios_post_cmos_nibble
    call    near bios_post_newline
    mov     si, 0x437F
    call    near bios_rom_print_si
    mov     si, 0x45BF
    push    ds
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
    mov     ax, [0x0042]
    pop     ds
    cmp     ax, 0xC800
    jb      short bios_post_video_base_display
    cmp     ax, 0xE000
    jb      short bios_post_video_base_ready
    cmp     ax, 0xF000
    jb      short bios_post_video_base_display
bios_post_video_base_ready:
    int     0x11
    mov     si, 0x458F
    and     al, 0x30
    cmp     al, 0x30
    je      short bios_post_video_base_display
    mov     si, 0x459F
    cmp     al, 0x20
    je      short bios_post_video_base_display
    mov     si, 0x45AF
bios_post_video_base_display:
    call    near bios_rom_print_si
    mov     si, 0x440F
    call    near bios_rom_print_si
    mov     cx, 0x0004
    mov     si, 0x0400
    call    near bios_post_print_word_list
    call    near bios_post_newline
    mov     si, 0x4397
    call    near bios_rom_print_si
    mov     cx, 0x0008
    mov     si, 0xFFF5
bios_post_rom_id_loop:
    mov     al, [cs:si]
    inc     si
    mov     ah, 0x0E
    int     0x10
    loop    bios_post_rom_id_loop
    mov     cx, 0x0007
bios_post_rom_id_delay:
    call    near 0x098A
    loop    bios_post_rom_id_delay
    mov     si, 0x4427
    call    near bios_rom_print_si
    mov     cx, 0x0003
    mov     si, 0x0408
    call    near bios_post_print_word_list
    call    near bios_post_newline
    ret

bios_post_print_word_list:
    push    ds
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
bios_post_print_word_list_loop:
    mov     ax, [si]
    inc     si
    inc     si
    db      0x0B, 0xC0                 ; or ax, ax
    je      short bios_post_print_word_list_next
    push    ax
    db      0x8A, 0xC4                 ; mov al, ah
    call    near bios_print_hex_nibble
    pop     ax
    call    near bios_print_hex_byte
    mov     ax, 0x0E2C
    int     0x10
    mov     ch, 0x55
bios_post_print_word_list_next:
    dec     cl
    jne     short bios_post_print_word_list_loop
    pop     ds
    db      0x0A, 0xED                 ; or ch, ch
    jne     short bios_post_print_word_list_done
    mov     si, 0x457F
    call    near bios_rom_print_si
    ret
bios_post_print_word_list_done:
    call    near 0x0985
    ret

bios_post_cmos_nibble:
    mov     si, 0x457F
    and     al, 0x0F
    je      short bios_post_cmos_nibble_empty
    cmp     al, 0x0F
    jne     short bios_post_cmos_nibble_numeric
    db      0x8A, 0xC4                 ; mov al, ah
    call    near 0xEE94
bios_post_cmos_nibble_numeric:
    db      0x32, 0xE4                 ; xor ah, ah
    call    near bios_print_decimal
    ret
bios_post_cmos_nibble_empty:
    call    near bios_rom_print_si
    ret

bios_post_cmos_option:
    push    ax
    mov     si, 0x457F
    db      0x25, 0x0F, 0x00           ; and ax, 000Fh
    je      short bios_post_cmos_option_print
    mov     si, 0x452F
    dec     ax
    je      short bios_post_cmos_option_print
    mov     si, 0x453F
    dec     ax
    je      short bios_post_cmos_option_print
    mov     si, 0x454F
    dec     ax
    je      short bios_post_cmos_option_print
    mov     si, 0x455F
    dec     ax
    je      short bios_post_cmos_option_print
    mov     si, 0x456F
bios_post_cmos_option_print:
    call    near bios_rom_print_si
    pop     ax
    ret
bios_post_newline:
    push    bx
    push    cx
    push    dx
    mov     ah, 0x03
    mov     bh, 0x00
    int     0x10
    db      0x32, 0xF6                 ; xor dh, dh
    mov     cx, 0x004C
    db      0x2B, 0xCA                 ; sub cx, dx
    jcxz    bios_post_newline_column_ready
bios_post_newline_delay:
    call    near 0x098A
    loop    bios_post_newline_delay
bios_post_newline_column_ready:
    mov     ax, 0x0EBA
    int     0x10
    pop     dx
    pop     cx
    pop     bx
    mov     ax, 0x0E0D
    int     0x10
    mov     ax, 0x0E0A
    int     0x10
    ret

bios_post_kb_suffix:
    call    near 0x098A
    mov     ax, 0x0E4B
    int     0x10
    mov     ax, 0x0E42
    int     0x10
    call    near bios_post_newline
    ret

bios_print_decimal:
    mov     cx, 0x000A
bios_print_decimal_divide:
    db      0x33, 0xD2                 ; xor dx, dx
    div     cx
    db      0x0B, 0xC0                 ; or ax, ax
    je      short bios_print_decimal_emit
    push    dx
    call    near bios_print_decimal_divide
    pop     dx
bios_print_decimal_emit:
    db      0x8B, 0xC2                 ; mov ax, dx
    db      0x0D, 0x30, 0x0E           ; or ax, 0E30h
    int     0x10
    ret

bios_post_cpu_info_select:
    pushf
    cli
    mov     ax, 0xF000
    push    ax
    popf
    pushf
    pop     ax
    and     ah, 0xF0
    mov     si, 0x449F
    jne     short bios_post_cpu_info_probe
    JMP_ABS 0x41DF
bios_post_cpu_info_probe:
    smsw    ax
    db      0x0A, 0xE4                 ; or ah, ah
    je      short bios_post_cpu_type_select
bios_post_cpu_protected_mode:
    push    ax
    mov     eax, cr0
    push    eax
    and     al, 0xEF
    mov     cr0, eax
    mov     eax, cr0
    test    al, 0x10
    pop     eax
    mov     cr0, eax
    pop     ax
    mov     si, 0x447F
    jne     short bios_post_cpu_v86
    db      0x0A, 0xE4                 ; or ah, ah
    jne     short bios_post_cpu_info_display
    mov     si, 0x44CF
    mov     al, 0xB3
    call    near 0xEE94
    test    al, 0x02
    je      short bios_post_cpu_info_display
    mov     si, 0x44DF
    jmp     short bios_post_cpu_info_display
bios_post_cpu_v86:
    mov     si, 0x448F
    db      0x0A, 0xE4                 ; or ah, ah
    jne     short bios_post_cpu_info_display
    mov     si, 0x44AF
    mov     al, 0xB3
    call    near 0xEE94
    test    al, 0x02
    je      short bios_post_cpu_info_display
    mov     si, 0x44BF
    jmp     short bios_post_cpu_info_display
bios_post_cpu_type_select:
    mov     al, 0xB3
    call    near 0xEE94
    test    al, 0x04
    jne     short bios_post_cpu_protected_mode
    test    al, 0x08
    jne     short bios_post_cpu_486_mode
    test    al, 0x02
    mov     si, 0x444F
    jne     short bios_post_cpu_info_display
    int     0x11
    test    al, 0x02
    mov     si, 0x445F
    jne     short bios_post_cpu_info_display
    mov     al, [cs:0xB513]
    call    near 0x8300
    mov     si, 0x443F
    je      short bios_post_cpu_info_display
    mov     si, 0x446F
    jmp     short bios_post_cpu_info_display
bios_post_cpu_486_mode:
    test    al, 0x02
    mov     si, 0x44FF
    jne     short bios_post_cpu_info_display
    mov     si, 0x44EF
bios_post_cpu_info_display:
    mov     ah, 0xFF
bios_post_cpu_info_emit:
    call    near bios_rom_print_si
    popf
    ret

bios_post_equipment_display:
    pushf
    push    ax
    int     0x11
    test    al, 0x02
    mov     si, 0x457F
    je      short bios_post_equipment_no_math
    mov     si, 0x450F
    call    near bios_rom_print_si
    pop     ax
    call    near bios_post_equipment_suffix
    jae     short bios_post_equipment_done
    mov     cx, 0x0008
bios_post_equipment_delay1:
    call    near 0x0985
    loop    bios_post_equipment_delay1
    mov     ax, 0x0E2C
    int     0x10
    call    near bios_rom_print_si
    mov     cx, 0x0008
bios_post_equipment_delay2:
    call    near 0x0985
    loop    bios_post_equipment_delay2
    jmp     short bios_post_equipment_done
bios_post_equipment_no_math:
    pop     ax
    call    near bios_post_equipment_suffix
    call    near bios_rom_print_si
bios_post_equipment_done:
    popf
    ret

bios_post_equipment_suffix:
    db      0x0A, 0xE4                 ; or ah, ah
    je      short bios_post_equipment_suffix_done
    db      0x66, 0x33, 0xC0           ; xor eax, eax
    int     0x11
    db      0x66, 0xC1, 0xE0, 0x08    ; shl eax, 8
    jae     short bios_post_equipment_suffix_done
    mov     si, 0x451F
bios_post_equipment_suffix_done:
    ret

%if ($ - rom_start) != 0x4231
    %error "POST system-configuration display code must end at 4231h"
%endif

incbin  "ami486.bin", ($ - rom_start), (0x4628 - ($ - rom_start)) ; inherited strings/data from 4231h to 4627h

; F000:4628 — Setup hard-disk utility main handler.
bios_hd_utility_entry:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    mov     byte [0xE422], 0x03
    JMP_ABS 0x4701

; 4633h is an alternate loop entry reached from the back-edge at 4744h.
bios_hd_utility_alternate_loop:
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     ax, 0x0E01
    mov     dx, 0x174E
    call    near 0x5821
    mov     al, [0xE1AC]
    mov     [0xE189], al
    mov     byte [0xE1AC], 0x00
bios_hd_utility_option_loop:
    call    near bios_hd_utility_coordinate
    db      0x8B, 0xC8                 ; mov cx, ax
    mov     al, [0xE1AC]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    shl     bx, 1
    shl     bx, 1
    mov     bx, [bx+0x38AD]
    db      0x8B, 0xC1                 ; mov ax, cx
    call    near 0x58D3
    inc     byte [0xE1AC]
    cmp     byte [0xE1AC], 0x03
    jl      short bios_hd_utility_option_loop
    mov     al, [0xE189]
    mov     [0xE1AC], al
bios_hd_utility_refresh:
    mov     al, [0xE1A5]
    mov     [0xE19F], al
    call    near bios_hd_utility_coordinate
    dec     ax
    mov     [0xE180], ax
    mov     dl, 0x12
    call    near 0x581C
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    call    near 0x5902
    mov     [0xE182], ax
    db      0x3D, 0x0D, 0x00           ; cmp ax, 000Dh
    je      short bios_hd_utility_exit_dialog
    mov     ax, [0xE180]
    mov     dl, 0x12
    call    near 0x581C
    mov     ax, [0xE182]
    db      0x2D, 0x1B, 0x00           ; sub ax, 001Bh
    jne     short bios_hd_utility_key_dispatch
    JMP_ABS 0x474E
bios_hd_utility_key_dispatch:
    db      0x2D, 0x21, 0x01           ; sub ax, 0121h
    jb      short bios_hd_utility_refresh
    db      0x2D, 0x01, 0x00           ; sub ax, 0001h
    jbe     short bios_hd_utility_palette
    db      0x2D, 0x0B, 0x00           ; sub ax, 000Bh
    je      short bios_hd_utility_previous
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_hd_utility_previous
    dec     ax
    dec     ax
    je      short bios_hd_utility_next
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_hd_utility_next
    jmp     short bios_hd_utility_refresh
bios_hd_utility_previous:
    dec     byte [0xE1AC]
    jns     short bios_hd_utility_refresh
    mov     byte [0xE1AC], 0x02
    jmp     short bios_hd_utility_refresh
bios_hd_utility_next:
    inc     byte [0xE1AC]
    cmp     byte [0xE1AC], 0x03
    jne     short bios_hd_utility_refresh
    mov     byte [0xE1AC], 0x00
    jmp     short bios_hd_utility_refresh
bios_hd_utility_palette:
    call    near 0x56AE
    jmp     short bios_hd_utility_common_screen
bios_hd_utility_exit_dialog:
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x0801
    mov     dx, 0x174E
    call    near 0x5802
    call    near 0x4891

; Common display setup and utility screen.
bios_hd_utility_common_screen:
    call    near 0x0995
    lea     bx, [0x3140]
    lea     ax, [0x37C3]
    call    near bios_setup_menu_header
    mov     ax, 0x0D01
    mov     dl, 0x4E
    mov     bx, 0x9000
    call    near 0x5862
    lea     bx, [0x36F5]
    mov     ax, 0x0426
    call    near 0x58D3
    mov     byte [0xE189], 0x00
    call    near bios_hd_utility_drive_status
    inc     byte [0xE189]
    call    near bios_hd_utility_drive_status
    lea     bx, [0x376E]
    mov     ax, 0x0828
    call    near 0x58BE
    cmp     byte [0xE012], 0x00
    je      short bios_hd_utility_no_drive
    JMP_ABS 0x4633
bios_hd_utility_no_drive:
    lea     bx, [0x3757]
    call    near bios_setup_menu_metric_formatter
bios_hd_utility_exit:
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

; 4752h returns AX = 101Fh + selected utility index in AH.
bios_hd_utility_coordinate:
    mov     ah, [0xE1AC]
    db      0x2A, 0xC0                 ; sub al, al
    add     ax, 0x101F
    ret

; 475Ch selected-drive/status renderer.
bios_hd_utility_drive_status:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0002
    push    si
    mov     al, [0xE012]
    mov     [bp-0x01], al
    cmp     byte [0xE189], 0x00
    jne     short bios_hd_utility_drive_nibble_ready
    mov     cl, 0x04
    shr     byte [bp-0x01], cl
bios_hd_utility_drive_nibble_ready:
    and     byte [bp-0x01], 0x0F
    je      short bios_hd_utility_drive_status_done
    cmp     byte [bp-0x01], 0x0F
    jne     short bios_hd_utility_drive_type_resolved
    mov     al, [0xE189]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    mov     al, [bx+0xE019]
    mov     [bp-0x01], al
bios_hd_utility_drive_type_resolved:
    mov     al, [0xE189]
    cbw
    db      0x8B, 0xD0                 ; mov dx, ax
    mov     al, [bp-0x01]
    call    near 0x5AB5
bios_hd_utility_drive_status_done:
    mov     al, [0xE189]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    mov     al, [bp-0x01]
    mov     [bx+0xE1AD], al
    db      0x8A, 0xFB                 ; mov bh, bl
    add     bh, 0x05
    db      0x2A, 0xDB                 ; sub bl, bl
    mov     [0xE180], bx
    mov     cl, [0xE189]
    add     cl, 0x43
    mov     [0x3727], cl
    lea     ax, [bx+0x04]
    lea     bx, [0x371D]
    call    near 0x58D3
    cmp     byte [bp-0x01], 0x00
    jne     short bios_hd_utility_drive_present
    cmp     byte [0xE187], 0x09
    jne     short bios_hd_utility_drive_absent_default
    mov     ax, [0xE180]
    db      0x05, 0x18, 0x00           ; add ax, 0018h
    lea     bx, [0x3731]
bios_hd_utility_drive_render:
    call    near 0x58D3
    JMP_ABS 0x488C
bios_hd_utility_drive_absent_default:
    mov     ax, [0xE180]
    db      0x05, 0x18, 0x00           ; add ax, 0018h
    lea     bx, [0x373F]
    jmp     short bios_hd_utility_drive_render
bios_hd_utility_drive_present:
    cmp     byte [bp-0x01], 0x2F
    jne     short bios_hd_utility_drive_fields
    mov     ax, [0xE180]
    db      0x05, 0x1A, 0x00           ; add ax, 001Ah
    lea     bx, [0x374C]
    call    near 0x58D3
bios_hd_utility_drive_fields:
    mov     ax, [0xE180]
    db      0x05, 0x18, 0x00           ; add ax, 0018h
    mov     bl, [bp-0x01]
    db      0x2A, 0xFF                 ; sub bh, bh
    mov     dx, 0x0002
    call    near 0x09EB
    mov     ax, [0xE180]
    db      0x05, 0x26, 0x00           ; add ax, 0026h
    mov     dx, 0x0005
    mov     bx, [0xE411]
    call    near 0x09EB
    mov     ax, [0xE180]
    db      0x05, 0x2C, 0x00           ; add ax, 002Ch
    mov     bl, [0xE413]
    db      0x2A, 0xFF                 ; sub bh, bh
    mov     dx, 0x0003
    call    near 0x09EB
    mov     ax, [0xE180]
    db      0x05, 0x32, 0x00           ; add ax, 0032h
    mov     dx, 0x0005
    mov     bx, [0xE416]
    call    near 0x09EB
    mov     ax, [0xE180]
    db      0x05, 0x38, 0x00           ; add ax, 0038h
    mov     dx, 0x0005
    mov     bx, [0xE41D]
    call    near 0x09EB
    mov     ax, [0xE180]
    db      0x05, 0x3E, 0x00           ; add ax, 003Eh
    mov     bl, [0xE41F]
    db      0x2A, 0xFF                 ; sub bh, bh
    mov     dx, 0x0003
    call    near 0x09EB
    add     word [0xE180], 0x44
    call    near 0x5BD5
    db      0x8B, 0xF0                 ; mov si, ax
    cmp     si, 0xFFFF
    jne     short bios_hd_utility_drive_resolved
    lea     bx, [0x37BD]
    mov     ax, [0xE180]
    JMP_ABS 0x47DE
bios_hd_utility_drive_resolved:
    db      0x8B, 0xD8                 ; mov bx, ax
    mov     ax, [0xE180]
    mov     dx, 0x0005
    call    near 0x09EB
bios_hd_utility_drive_status_epilogue:
    pop     si
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x4891
    %error "Setup hard-disk utility handler block must end at 4891h"
%endif

; F000:4891 — Setup hard-disk utility option panel and callback dispatcher.
bios_hd_utility_panel:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x000A
    push    di
    push    si
    mov     byte [bp-0x04], 0x00
    mov     al, [0xE1AC]
    cbw
    db      0x8B, 0xF8                 ; mov di, ax
    shl     di, 1
    shl     di, 1
    add     di, 0x38AD
    lea     bx, [0x37E9]
    mov     ax, 0x1828
    call    near bios_setup_menu_value_input
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     dh, [di+0x02]
    db      0x2A, 0xD2                 ; sub dl, dl
    add     dx, 0x0B21
    mov     ax, 0x0802
    mov     bx, 0x0003
    call    near 0x578D
    mov     bx, [di]
    mov     ax, 0x0912
    call    near 0x58BE
    mov     ax, 0x0A03
    mov     dl, 0x1E
    mov     bx, 0x9000
    call    near 0x5862
    mov     byte [bp-0x01], 0x00
    mov     word [0xE180], 0x0B04
    mov     al, [di+0x03]
    mov     [bp-0x02], al
    mov     [bp-0x03], al
    jmp     short bios_hd_utility_option_count
bios_hd_utility_option_draw:
    test    byte [bp-0x02], 0x01
    je      short bios_hd_utility_option_next
    mov     bl, [bp-0x01]
    db      0x2A, 0xFF                 ; sub bh, bh
    shl     bx, 1
    mov     bx, [bx+0x3873]
    mov     ax, [0xE180]
    call    near 0x58D3
    mov     dx, [0xE180]
    add     dx, 0x0016
    mov     al, 0x3F
    call    near 0x58EE
    db      0x80, 0x06, 0x81, 0xE1, 0x01 ; add byte [E181], 1
bios_hd_utility_option_next:
    inc     byte [bp-0x01]
    shr     byte [bp-0x02], 1
bios_hd_utility_option_count:
    cmp     byte [bp-0x01], 0x05
    jb      short bios_hd_utility_option_draw

    mov     byte [bp-0x01], 0x00
    mov     word [0xE180], 0x0B1C
    mov     al, [bp-0x03]
    mov     [bp-0x02], al
    jmp     short bios_hd_utility_callback_count
bios_hd_utility_callback_loop:
    test    byte [bp-0x02], 0x01
    je      short bios_hd_utility_callback_next
    mov     ax, [0xE180]
    call    near 0x09C1
    mov     bl, [bp-0x01]
    db      0x2A, 0xFF                 ; sub bh, bh
    shl     bx, 1
    mov     ax, [bx+0x38B9]
    mov     [bp-0x0A], ax
    call    word [bp-0x0A]
    mov     [bp-0x05], al
    cmp     al, 0x1B
    jne     short bios_hd_utility_callback_not_escape
    JMP_ABS 0x4AE8
bios_hd_utility_callback_not_escape:
    db      0x80, 0x06, 0x81, 0xE1, 0x01 ; add byte [E181], 1
bios_hd_utility_callback_next:
    inc     byte [bp-0x01]
    shr     byte [bp-0x02], 1
bios_hd_utility_callback_count:
    cmp     byte [bp-0x01], 0x05
    jb      short bios_hd_utility_callback_loop
    cmp     byte [bp-0x05], 0x59
    je      short bios_hd_utility_after_confirm
    JMP_ABS 0x48B5
bios_hd_utility_after_confirm:
    mov     byte [0xE1AB], 0x00
    mov     al, [0xE1A7]
    mov     [0xE19F], al
    mov     ax, 0x082B
    mov     dx, 0x0F4D
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x34C1]
    mov     ax, 0x093C
    call    near 0x58A1
    lea     bx, [0x3982]
    mov     ax, 0x0B3C
    call    near 0x58C6
    lea     bx, [0x3998]
    mov     ax, 0x0C3C
    call    near 0x58C6
    lea     bx, [0x39AE]
    mov     ax, 0x0E3C
    call    near 0x58C6
    mov     word [0xE180], 0x0E49
    call    near 0xF571
    call    near 0x5985
    cmp     al, 0x59
    je      short bios_hd_utility_confirm_yes
    JMP_ABS 0x4ACD
bios_hd_utility_confirm_yes:
    mov     ax, 0x082B
    mov     dx, 0x0F4D
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x39C7]
    mov     ax, 0x093C
    call    near 0x58BE
    lea     bx, [0x394B]
    mov     ax, 0x0B2D
    call    near 0x58D3
    lea     bx, [0x395E]
    mov     ax, 0x0B40
    call    near 0x58D3
    lea     bx, [0x39CE]
    mov     ax, 0x0D3C
    call    near 0x58A1
    cmp     byte [0xE1AC], 0x02
    jne     short bios_hd_utility_drive_choice_ready
    mov     byte [bp-0x04], 0x01
bios_hd_utility_drive_choice_ready:
    cmp     byte [0xE1AC], 0x01
    jne     short bios_hd_utility_format_check_done
    cmp     byte [bp-0x05], 0x59
    jne     short bios_hd_utility_format_check_done
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     ax, 0x102B
    mov     dx, 0x174D
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x3A66]
    mov     ax, 0x113C
    call    near 0x58BE
    mov     di, 0x0001
    mov     si, 0x1232
bios_hd_utility_cylinder_head_loop:
    mov     [0xE180], si
    db      0x8B, 0xC6                 ; mov ax, si
    mov     dx, 0x0001
    db      0x8B, 0xDF                 ; mov bx, di
    call    near 0x09EB
    mov     ax, [0xE180]
    inc     ax
    inc     ax
    lea     bx, [0x3A81]
    call    near 0x58D3
    add     si, 0x0100
    inc     di
    cmp     si, 0x1532
    jbe     short bios_hd_utility_cylinder_head_loop
    lea     bx, [0x3A89]
    mov     ax, 0x163C
    call    near 0x58BE
bios_hd_utility_format_check_done:
    call    near 0x2FA3
    mov     [bp-0x05], al
    mov     al, [0xE1A7]
    mov     [0xE19F], al
    mov     ax, 0x0D2C
    mov     dl, 0x21
    call    near 0x57FD
    cmp     byte [bp-0x05], 0x1B
    je      short bios_hd_utility_format_result
    cmp     byte [bp-0x05], 0x03
    jbe     short bios_hd_utility_format_choice
bios_hd_utility_format_result:
    lea     bx, [0x39ED]
    mov     ax, 0x0D3C
    call    near 0x58A1
    JMP_ABS 0x49B1
bios_hd_utility_format_choice:
    cmp     byte [bp-0x05], 0x00
    jne     short bios_hd_utility_format_choice_indexed
    mov     ax, 0x0B2C
    mov     dl, 0x21
    call    near 0x57FD
    lea     bx, [0x39F8]
    mov     ax, 0x0B3C
    jmp     short bios_hd_utility_format_choice_render
bios_hd_utility_format_choice_indexed:
    mov     bl, [bp-0x05]
    db      0x2A, 0xFF                 ; sub bh, bh
    shl     bx, 1
    mov     bx, [bx+0x3A5E]
    mov     ax, 0x0D3C
bios_hd_utility_format_choice_render:
    call    near 0x58A1
    lea     bx, [0x36DB]
    mov     ax, 0x0E3C
    call    near 0x58A1
    call    near 0x5902
bios_hd_utility_panel_exit:
    cmp     byte [bp-0x04], 0x00
    je      short bios_hd_utility_panel_return
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x082B
    mov     dx, 0x174E
    call    near 0x5802
    call    near 0x4BDA
    call    near 0x4CEE
bios_hd_utility_panel_return:
    pop     si
    pop     di
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x4AEE
    %error "Setup utility panel must end at 4AEEh"
%endif

; B7BA table callback: update selected drive/type selector.
bios_hd_utility_drive_type_callback:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    cmp     byte [0xE1AE], 0x00
    jne     short bios_hd_utility_drive_type_selected
    mov     byte [0x3A45], 0x43
    jmp     short bios_hd_utility_drive_type_draw
bios_hd_utility_drive_type_selected:
    cmp     byte [0xE1AD], 0x00
    jne     short bios_hd_utility_drive_type_prompt_entry
    mov     byte [0x3A45], 0x44
bios_hd_utility_drive_type_draw:
    call    near bios_hd_utility_drive_type_render
    mov     byte [0xE182], 0x0D
    jmp     short bios_hd_utility_drive_type_loop
bios_hd_utility_drive_type_prompt_entry:
    call    near 0x099D
bios_hd_utility_drive_type_prompt:
    call    near bios_hd_utility_drive_type_render
    call    near 0x591A
    mov     [0xE182], ax
    db      0x2D, 0x0D, 0x00           ; sub ax, 000Dh
    je      short bios_hd_utility_drive_type_loop
    db      0x2D, 0x0E, 0x00           ; sub ax, 000Eh
    je      short bios_hd_utility_drive_type_loop
    db      0x2D, 0x28, 0x00           ; sub ax, 0028h
    jb      short bios_hd_utility_drive_type_prompt
    db      0x2D, 0x01, 0x00           ; sub ax, 0001h
    ja      short bios_hd_utility_drive_type_prompt
    mov     al, [0xE182]
    mov     [0x3A45], al
    jmp     short bios_hd_utility_drive_type_prompt
bios_hd_utility_drive_type_loop:
    mov     al, [0x3A45]
    db      0x2A, 0x06, 0x21, 0xE4    ; sub al, [E421]
    cmp     al, 0x43
    je      short bios_hd_utility_drive_type_done
    mov     word [0xE423], 0x0000
bios_hd_utility_drive_type_done:
    mov     al, [0x3A45]
    sub     al, 0x43
    mov     [0xE421], al
    mov     al, [0xE182]
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

bios_hd_utility_drive_type_render:
    mov     al, [0x3A45]
    mov     dx, [0xE180]
    call    near 0x58EE
    ret

%if ($ - rom_start) != 0x4B68
    %error "Drive-type callback block must end at 4B68h"
%endif

; F000:4B68 — selected drive type renderer.
bios_hd_utility_selected_drive:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0002
    mov     bl, [0xE421]
    db      0x2A, 0xFF                 ; sub bh, bh
    mov     bl, [bx+0xE1AD]
    mov     [bp-0x01], bl
    mov     ax, [0xE180]
    mov     dx, 0x0002
    call    near 0x09EB
    mov     dl, [0xE421]
    db      0x2A, 0xF6                 ; sub dh, dh
    mov     al, [bp-0x01]
    call    near 0x5AB5
    mov     al, 0x0D
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

; 4B96h repeats the extended-disk command until the controller status clears.
bios_hd_utility_extended_disk_command:
bios_hd_utility_extended_disk_retry:
    mov     al, 0x03
    push    ax
    mov     ax, [0xE180]
    mov     dx, 0x0010
    lea     bx, [0xE422]
    call    near 0x06C9
    mov     [0xE184], al
    cmp     byte [0xE422], 0x00
    je      short bios_hd_utility_extended_disk_retry
    ret

; 4BB1h confirms and commits the utility operation.
bios_hd_utility_commit_operation:
    call    near bios_hd_utility_draw_confirmation
    call    near 0x5985
    mov     [0xE184], al
    cmp     al, 0x59
    jne     short bios_hd_utility_commit_display
    call    near 0x4CEE
bios_hd_utility_commit_display:
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x0823
    mov     dx, 0x174E
    call    near 0x5802
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     al, [0xE184]
    ret

; 4BDAh draws the confirmation panel and iterates the selected geometry rows.
bios_hd_utility_draw_confirmation:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0006
    push    si
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     ax, 0x0839
    mov     dx, 0x164D
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x38C3]
    mov     ax, 0x093C
    call    near 0x58D3
    mov     ax, 0x0948
    mov     dx, 0x0005
    mov     bx, [0xE423]
    call    near 0x09EB
    call    near 0x5891
    mov     ax, 0x093A
    mov     dl, 0x13
    call    near 0x581C
    call    near 0x58B5
    mov     ax, 0x0A3A
    mov     dl, 0x13
    mov     bx, 0x9000
    call    near 0x5862
    lea     bx, [0x38CF]
    mov     ax, 0x0B3B
    call    near 0x58D3
    mov     si, 0x000A
    cmp     [0xE423], si
    jae     short bios_hd_utility_geometry_limit_ready
    mov     si, [0xE423]
bios_hd_utility_geometry_limit_ready:
    cmp     word [0xE425], 0x0000
    jge     short bios_hd_utility_start_cylinder_nonnegative
    mov     word [0xE425], 0x0000
bios_hd_utility_start_cylinder_nonnegative:
    cmp     [0xE425], si
    jb      short bios_hd_utility_start_cylinder_ready
    lea     ax, [si-0x01]
    mov     [0xE425], ax
bios_hd_utility_start_cylinder_ready:
    mov     [bp-0x06], si
    mov     ax, [0xE423]
    cmp     [0xE427], ax
    jbe     short bios_hd_utility_end_cylinder_ready
    mov     [0xE427], ax
bios_hd_utility_end_cylinder_ready:
    cmp     word [0xE427], 0x0000
    jne     short bios_hd_utility_end_cylinder_nonzero
    inc     word [0xE427]
bios_hd_utility_end_cylinder_nonzero:
    mov     word [bp-0x02], 0x0000
    mov     ax, [0xE427]
    sub     ax, [0xE425]
    mov     [bp-0x04], ax
    jmp     short bios_hd_utility_geometry_loop_test
bios_hd_utility_geometry_loop:
    mov     ax, [0xE423]
    cmp     [bp-0x04], ax
    ja      short bios_hd_utility_geometry_loop_done
    mov     ax, [bp-0x02]
    mov     dx, [bp-0x04]
    call    near bios_hd_utility_draw_geometry_row
    inc     word [bp-0x02]
    inc     word [bp-0x04]
bios_hd_utility_geometry_loop_test:
    mov     ax, [bp-0x06]
    cmp     [bp-0x02], ax
    jb      short bios_hd_utility_geometry_loop
bios_hd_utility_geometry_loop_done:
    pop     si
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

; 4CA2h draws one geometry row from the selected row/column indices.
bios_hd_utility_draw_geometry_row:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    push    dx
    push    di
    push    si
    call    near bios_hd_utility_geometry_coordinate
    mov     dx, 0x0005
    mov     bx, [bp-0x02]
    db      0x8B, 0xF0                 ; mov si, ax
    call    near 0x09EB
    lea     ax, [si+0x06]
    mov     bx, [bp-0x02]
    db      0x8B, 0xCB                 ; mov cx, bx
    shl     bx, 1
    db      0x03, 0xD9                 ; add bx, cx
    lea     cx, [bx+0xE436]
    mov     bx, [bx+0xE436]
    mov     dx, 0x0005
    db      0x8B, 0xF9                 ; mov di, cx
    call    near 0x09EB
    lea     ax, [si+0x0D]
    mov     bl, [di+0x02]
    db      0x2A, 0xFF                 ; sub bh, bh
    mov     dx, 0x0003
    call    near 0x09EB
    pop     si
    pop     di
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

; 4CE6h converts a one-byte value to the BIOS utility coordinate.
bios_hd_utility_geometry_coordinate:
    db      0x8A, 0xE0                 ; mov ah, al
    db      0x2A, 0xC0                 ; sub al, al
    add     ax, 0x0C3B
    ret

%if ($ - rom_start) != 0x4CEE
    %error "Drive renderer/geometry helper block must end at 4CEEh"
%endif

; F000:4CEEh — disk-size and geometry configuration menu.
bios_hd_size_menu:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0002
    push    di
    push    si
    mov     al, [0xE1A6]
    mov     [0xE19F], al
    mov     ax, 0x0823
    mov     dx, 0x0F37
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x38E1]
    mov     ax, 0x092D
    call    near 0x58BE
    mov     ax, 0x0A24
    mov     dl, 0x13
    mov     bx, 0x9000
    call    near 0x5862
    mov     byte [0xE185], 0x00
bios_hd_size_option_loop:
    call    near bios_hd_size_option_coordinate
    db      0x8B, 0xC8                 ; mov cx, ax
    mov     al, [0xE185]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    shl     bx, 1
    mov     bx, [bx+0x3935]
    db      0x8B, 0xC1                 ; mov ax, cx
    call    near 0x58D3
    inc     byte [0xE185]
    cmp     byte [0xE185], 0x04
    jl      short bios_hd_size_option_loop
bios_hd_size_auto_reset:
    mov     byte [0xE185], 0x00
bios_hd_size_auto_loop:
    cmp     byte [0xE185], 0x00
    jne     short bios_hd_size_manual_check
    cmp     word [0xE423], 0x03E8
    jne     short bios_hd_size_input
bios_hd_size_auto_next:
    inc     byte [0xE185]
    cmp     byte [0xE185], 0x04
    jne     short bios_hd_size_auto_loop
    jmp     short bios_hd_size_auto_reset
bios_hd_size_manual_check:
    cmp     word [0xE423], 0x0000
    je      short bios_hd_size_auto_next
bios_hd_size_input:
    mov     al, [0xE1A7]
    mov     [0xE19F], al
    call    near bios_hd_size_option_coordinate
    db      0x8B, 0xF8                 ; mov di, ax
    dec     di
    db      0x8B, 0xC7                 ; mov ax, di
    mov     dl, 0x13
    call    near 0x581C
    call    near 0x5902
    db      0x8B, 0xF0                 ; mov si, ax
    cmp     si, 0x000D
    jne     short bios_hd_size_key_dispatch
    mov     al, [0xE185]
    cbw
    db      0x8B, 0xD8                 ; mov bx, ax
    shl     bx, 1
    mov     ax, [bx+0x393D]
    mov     [bp-0x02], ax
    call    word [bp-0x02]
    call    near bios_hd_utility_draw_confirmation
bios_hd_size_key_dispatch:
    mov     al, [0xE1A6]
    mov     [0xE19F], al
    db      0x8B, 0xC7                 ; mov ax, di
    mov     dl, 0x13
    call    near 0x581C
    db      0x8B, 0xC6                 ; mov ax, si
    db      0x2D, 0x1B, 0x00           ; sub ax, 001Bh
    je      short bios_hd_size_exit
    db      0x2D, 0x2D, 0x01           ; sub ax, 012Dh
    je      short bios_hd_size_previous
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_hd_size_previous
    dec     ax
    dec     ax
    je      short bios_hd_size_auto_next
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_hd_size_auto_next
    jmp     short bios_hd_size_auto_loop
bios_hd_size_previous:
    dec     byte [0xE185]
    js      short bios_hd_size_previous_wrap
    JMP_ABS 0x4D48
bios_hd_size_previous_wrap:
    mov     byte [0xE185], 0x03
    JMP_ABS 0x4D48
bios_hd_size_exit:
    pop     si
    pop     di
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

; 4DDDh calculates the screen coordinate from the selected option row.
bios_hd_size_option_coordinate:
    mov     ah, [0xE185]
    db      0x2A, 0xC0                 ; sub al, al
    add     ax, 0x0B25
    ret

; 4DE7h initializes the geometry table and invokes the input callback.
bios_hd_size_geometry_initialize:
    cmp     word [0xE423], 0x0000
    je      short bios_hd_size_geometry_initialize_done
    mov     ax, [0xE423]
    db      0x8B, 0xC8                 ; mov cx, ax
    shl     ax, 1
    db      0x03, 0xC1                 ; add ax, cx
    mov     bx, 0xE436
    db      0x03, 0xD8                 ; add bx, ax
    db      0x05, 0x39, 0xE4           ; add ax, E439h
    mov     dx, 0x0003
    call    near 0x594A
bios_hd_size_geometry_initialize_done:
    mov     ax, [0xE423]
    inc     ax
    call    near 0x4EE7
    db      0x3D, 0x1B, 0x00           ; cmp ax, 001Bh
    je      short bios_hd_size_geometry_initialize_return
    inc     word [0xE423]
    mov     ax, [0xE423]
    mov     [0xE427], ax
    mov     [0xE425], ax
bios_hd_size_geometry_initialize_return:
    ret

; 4E1Fh prompts for a new end-cylinder value.
bios_hd_size_edit_end:
    call    near bios_hd_size_edit_start_input
    db      0x3D, 0x1B, 0x00           ; cmp ax, 001Bh
    je      short bios_hd_size_edit_end_return
    mov     ax, [0xE427]
    call    near 0x4EE7
bios_hd_size_edit_end_return:
    ret

; 4E2Eh prompts for a new start-cylinder value.
bios_hd_size_edit_start:
    call    near bios_hd_size_edit_start_input
    db      0x3D, 0x1B, 0x00           ; cmp ax, 001Bh
    je      short bios_hd_size_edit_start_return
    mov     ax, [0xE427]
    db      0x8B, 0xD8                 ; mov bx, ax
    db      0x8B, 0xC8                 ; mov cx, ax
    shl     bx, 1
    db      0x03, 0xD9                 ; add bx, cx
    mov     dx, [0xE423]
    db      0x2B, 0xD0                 ; sub dx, ax
    db      0x8B, 0xC2                 ; mov ax, dx
    shl     dx, 1
    db      0x03, 0xD0                 ; add dx, ax
    db      0x8B, 0xC3                 ; mov ax, bx
    mov     bx, 0xE439
    db      0x03, 0xD8                 ; add bx, ax
    db      0x05, 0x36, 0xE4           ; add ax, E436h
    call    near 0x594A
    dec     word [0xE423]
bios_hd_size_edit_start_return:
    ret

; 4E5Fh resets the selected geometry count.
bios_hd_size_reset:
    mov     word [0xE423], 0x0000
    ret

; 4E66h edits the visible cylinder range and processes navigation keys.
bios_hd_size_edit_start_input:
    push    si
bios_hd_size_edit_start_loop:
    mov     al, [0xE1A5]
    mov     [0xE19F], al
    mov     ax, [0xE425]
    call    near bios_hd_utility_geometry_coordinate
    db      0x8B, 0xF0                 ; mov si, ax
    dec     si
    db      0x8B, 0xC6                 ; mov ax, si
    mov     dl, 0x13
    call    near 0x581C
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    call    near 0x5902
    mov     [0xE182], ax
    db      0x3D, 0x0D, 0x00           ; cmp ax, 000Dh
    je      short bios_hd_size_edit_start_done
    db      0x8B, 0xC6                 ; mov ax, si
    mov     dl, 0x13
    call    near 0x581C
    mov     ax, [0xE182]
    db      0x2D, 0x1B, 0x00           ; sub ax, 001Bh
    je      short bios_hd_size_edit_start_done
    db      0x2D, 0x2D, 0x01           ; sub ax, 012Dh
    je      short bios_hd_size_edit_start_previous
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_hd_size_edit_start_previous
    dec     ax
    dec     ax
    je      short bios_hd_size_edit_start_next
    db      0x2D, 0x03, 0x00           ; sub ax, 0003h
    je      short bios_hd_size_edit_start_next
    jmp     short bios_hd_size_edit_start_loop
bios_hd_size_edit_start_previous:
    cmp     word [0xE427], 0x0001
    jbe     short bios_hd_size_edit_start_loop
    dec     word [0xE427]
    dec     word [0xE425]
    jns     short bios_hd_size_edit_start_loop
bios_hd_size_edit_start_redraw:
    call    near bios_hd_utility_draw_confirmation
    jmp     short bios_hd_size_edit_start_loop
bios_hd_size_edit_start_next:
    mov     ax, [0xE423]
    cmp     [0xE427], ax
    jae     short bios_hd_size_edit_start_loop
    inc     word [0xE427]
    inc     word [0xE425]
    cmp     word [0xE425], 0x000A
    jl      short bios_hd_size_edit_start_loop
    jmp     short bios_hd_size_edit_start_redraw
bios_hd_size_edit_start_done:
    mov     ax, [0xE182]
    pop     si
    ret

%if ($ - rom_start) != 0x4EE7
    %error "Disk-size/geometry menu helper block must end at 4EE7h"
%endif

; F000:4EE7 — edit the selected hard-disk geometry record.
bios_hd_size_edit_record:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    sub     sp, 0x0006
    push    ax
    push    si
    mov     al, [0xE1A6]
    mov     [0xE19F], al
    mov     ax, 0x1118
    mov     dx, 0x1637
    mov     bx, 0x0003
    call    near 0x578D
    mov     ax, 0x1418
    mov     dl, 0x20
    mov     bx, 0x2016
    call    near 0x5862
    lea     bx, [0x3945]
    mov     ax, 0x121C
    call    near 0x58D3
    lea     bx, [0x3958]
    mov     ax, 0x1320
    call    near 0x58D3
    call    near 0x099D
    mov     bx, [bp-0x08]
    db      0x8B, 0xC3                 ; mov ax, bx
    shl     bx, 1
    db      0x03, 0xD8                 ; add bx, ax
    db      0x81, 0xC3, 0x36, 0xE4    ; add bx, E436h
    mov     [bp-0x02], bx
    mov     ax, [bx]
    mov     [bp-0x06], ax
    mov     al, [bx+0x02]
    mov     [bp-0x04], al
bios_hd_size_edit_record_loop:
    mov     al, 0x05
    push    ax
    mov     dx, [0xE411]
    dec     dx
    mov     ax, 0x122F
    lea     bx, [bp-0x06]
    call    near 0x06C9
    mov     [0xE182], ax
    db      0x3D, 0x1B, 0x00           ; cmp ax, 001Bh
    je      short bios_hd_size_edit_record_finish
    mov     al, 0x03
    push    ax
    mov     dl, [0xE413]
    db      0x2A, 0xF6                 ; sub dh, dh
    dec     dx
    mov     ax, 0x132F
    lea     bx, [bp-0x04]
    call    near 0x06C9
    mov     [0xE182], ax
bios_hd_size_edit_record_finish:
    db      0x3D, 0x1B, 0x00           ; cmp ax, 001Bh
    je      short bios_hd_size_edit_record_return
    mov     dx, 0x0001
    mov     si, 0xE439
bios_hd_size_edit_record_compare:
    cmp     [0xE423], dx
    jb      short bios_hd_size_edit_record_store
    cmp     [bp-0x08], dx
    je      short bios_hd_size_edit_record_not_match
    mov     ax, [si]
    cmp     [bp-0x06], ax
    jne     short bios_hd_size_edit_record_not_match
    mov     al, [bp-0x04]
    cmp     [si+0x02], al
    je      short bios_hd_size_edit_record_match
bios_hd_size_edit_record_not_match:
    inc     dx
    add     si, 0x0003
    jmp     short bios_hd_size_edit_record_compare
bios_hd_size_edit_record_match:
    lea     bx, [0x3967]
    mov     ax, 0x1528
    call    near 0x58A1
    call    near 0xF571
    jmp     short bios_hd_size_edit_record_loop
bios_hd_size_edit_record_store:
    mov     ax, [bp-0x06]
    mov     bx, [bp-0x02]
    mov     [bx], ax
    mov     al, [bp-0x04]
    mov     [bx+0x02], al
bios_hd_size_edit_record_return:
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x1118
    mov     dx, 0x1637
    call    near 0x5802
    call    near 0x0995
    mov     ax, [0xE182]
    pop     si
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x4FCF
    %error "Geometry-record editor must end at 4FCFh"
%endif

; F000:4FCF — Setup drive-type selection callback.
bios_hd_utility_drive_type_select:
    push    bp
    db      0x8B, 0xEC                 ; mov bp, sp
    push    ax
    mov     al, [0xE1A6]
    mov     [0xE19F], al
    mov     ax, 0x1102
    mov     dx, 0x1629
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x3AA0]
    mov     ax, 0x1215
    call    near 0x58A1
    mov     bl, [bp-0x02]
    db      0x2A, 0xFF                 ; sub bh, bh
    shl     bx, 1
    mov     bx, [bx+0x3BEC]
    mov     ax, 0x1315
    call    near 0x58A1
    lea     bx, [0x3C08]
    mov     ax, 0x1515
    call    near 0x58BE
    call    near 0xF571
bios_hd_utility_drive_type_wait:
    call    near 0x591A
    mov     [0xE182], ax
    db      0x3D, 0x52, 0x00           ; cmp ax, 0052h
    je      short bios_hd_utility_drive_type_finish
    ja      short bios_hd_utility_drive_type_wait
    sub     al, 0x41
    je      short bios_hd_utility_drive_type_finish
    sub     al, 0x08
    jne     short bios_hd_utility_drive_type_wait
bios_hd_utility_drive_type_finish:
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x1102
    mov     dx, 0x1629
    call    near 0x5802
    mov     al, [0xE182]
    db      0x8B, 0xE5                 ; mov sp, bp
    pop     bp
    ret

%if ($ - rom_start) != 0x5038
    %error "Drive-type selection callback must end at 5038h"
%endif

; F000:5038 — Setup hard-disk geometry/drive status display.
bios_hd_utility_geometry_screen:
    lea     bx, [0x3128]
    lea     ax, [0x380F]
    call    near bios_setup_menu_header
    mov     byte [0xE189], 0x00
bios_hd_utility_geometry_screen_loop:
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    mov     ax, 0x0A02
    mov     dx, 0x0E4D
    call    near 0x5802
    mov     al, [0xE1A4]
    mov     [0xE19F], al
    mov     ax, 0x0A18
    mov     dx, 0x0E36
    mov     bx, 0x0003
    call    near 0x578D
    lea     bx, [0x3C1F]
    mov     ax, 0x0C28
    call    near 0x58A1
    mov     al, [0xE189]
    call    near 0x5AEC
    mov     al, [0xE1A2]
    mov     [0xE19F], al
    lea     bx, [0x36F5]
    mov     ax, 0x0426
    call    near 0x58D3
    call    near bios_hd_utility_drive_status
    mov     al, [0xE189]
    call    near 0x5B7C
    inc     byte [0xE189]
    cmp     byte [0xE189], 0x02
    jl      short bios_hd_utility_geometry_screen_loop
    ret

%if ($ - rom_start) != 0x509E
    %error "HD utility geometry screen must end at 509Eh"
%endif

; F000:509E — POST extended-memory/controller setup and initial RAM probe.
; Entry is reached from the POST path through the 5F62h transfer.
bios_post_extended_memory_entry:
    mov     ax, 0x028F
    call    near 0xEE9D
    mov     al, 0x40
    out     0x80, al
    call    near 0xF3DB
    mov     al, 0x41
    out     0x80, al
    mov     di, 0x0600
    push    di
    mov     si, 0xE260
    mov     cx, 0x0030
    cli
    cld
    db      0x2E, 0xF3, 0xA5           ; rep movsw cs:[si] -> es:[di]
    pop     si
    db      0x26, 0xC7, 0x44, 0x0A, 0x00, 0x06 ; mov word es:[si+0Ah],0600h
    db      0x26, 0xC6, 0x44, 0x0C, 0x00      ; mov byte es:[si+0Ch],00h
    mov     bx, 0x0800
    mov     ah, 0x89
    mov     al, 0x42
    out     0x80, al
    int     0x15
    mov     al, 0x43
    out     0x80, al
    je      short bios_post_extended_memory_int15_ok
    mov     si, 0x7AB2
    jmp     near 0xF509
bios_post_extended_memory_int15_ok:
    call    near 0x5506
    mov     ax, 0x0040
    mov     es, ax
    mov     al, 0x44
    out     0x80, al
    db      0x33, 0xFF                 ; xor di, di
    mov     si, 0x0244
    mov     word [0x0238], 0xFFFF
    mov     word [0x023D], 0x0093
    push    ds
    mov     ax, 0x0038
    mov     ds, ax
    mov     ax, [0x0000]
    mov     cx, [0x0002]
    mov     word [0x0000], 0xFFFF
    mov     word [0x0002], 0xFFFF
    pop     ds
    push    ax
    push    cx
    mov     al, 0x45
    out     0x80, al
    mov     ax, 0x0010
    call    near 0x5305
    pop     cx
    pop     bx
    push    ax
    mov     al, 0x46
    out     0x80, al
    push    ds
    mov     ax, 0x0038
    mov     ds, ax
    mov     [0x0002], cx
    mov     [0x0000], bx
    pop     ds
    pop     ax
    push    ax
    dec     ax
    mov     bx, 0x000F
    db      0x3B, 0xC3                 ; cmp ax, bx
    je      short bios_post_extended_memory_skip_byte_probe
    call    near 0x534C
bios_post_extended_memory_skip_byte_probe:
    push    ax
    mov     al, 0x47
    out     0x80, al
    mov     ax, 0x0009
    mov     bx, 0x0000
    call    near 0x534C
    push    ax
    mov     al, 0x48
    out     0x80, al
    pop     ax
    mov     bx, 0x000A
    mov     byte [si], 0x00
    mov     byte [si+0x03], 0x00
    db      0x33, 0xD2                 ; xor dx, dx
    call    near 0x5371
    mov     al, 0x49
    out     0x80, al
    pop     ax
    pop     bx
    push    dx
    db      0x33, 0xD2                 ; xor dx, dx
    mov     byte [si], 0x0F
    mov     byte [si+0x03], 0x00
    cmp     bx, 0x0010
    je      short bios_post_extended_memory_skip_high_probe
    call    near 0x5371
bios_post_extended_memory_skip_high_probe:
    pop     bx
    xchg    bx, dx
    mov     al, 0x4A
    out     0x80, al
    push    word 0x5190
    push    word 0xFA4E
    ret

%if ($ - rom_start) != 0x5190
    %error "POST extended-memory entry block must end at 5190h"
%endif

; F000:5190 — continuation of POST memory/controller diagnostics.
; The RET at 518F transfers through the stack-crafted F000:FA4E path back here.
bios_post_memory_controller_continue:
    mov     al, 0x4B
    out     0x80, al
    db      0x0B, 0xED                 ; or bp, bp
    jns     short bios_post_memory_controller_chipset_path
    push    dx
    push    bx
    call    near 0x5434
    mov     cx, 0x0040
    cmp     bx, 0x002F
    ja      short bios_post_memory_controller_poll
    mov     cx, 0x0080
bios_post_memory_controller_poll:
    push    cx
    mov     cx, 0x0400
    call    near 0xE93C
    call    near 0x5448
    pop     cx
    loopnz  bios_post_memory_controller_poll
    db      0x0B, 0xD2                 ; or dx, dx
    je      short bios_post_memory_controller_clear_low_done
    mov     byte [si], 0x00
    mov     byte [si+0x03], 0x00
bios_post_memory_controller_clear_low:
    call    near 0x5448
    call    near 0x5513
    call    near 0x5520
    dec     dx
    jne     short bios_post_memory_controller_clear_low
bios_post_memory_controller_clear_low_done:
    mov     al, 0x4C
    out     0x80, al
    db      0x0B, 0xDB                 ; or bx, bx
    je      short bios_post_memory_controller_finish_low
    mov     byte [si], 0x0F
    mov     byte [si+0x03], 0x00
bios_post_memory_controller_clear_high:
    call    near 0x5448
    call    near 0x5513
    call    near 0x5520
    dec     bx
    jne     short bios_post_memory_controller_clear_high
bios_post_memory_controller_finish_low:
    mov     al, 0x4D
    out     0x80, al
    call    near 0x543D
    pop     bx
    pop     dx
    inc     dx
    jmp     short bios_post_memory_controller_set_map

bios_post_memory_controller_chipset_path:
    push    bp
    mov     bp, 0x0001
    push    bx
    db      0x33, 0xDB                 ; xor bx, bx
    mov     al, 0x4E
    out     0x80, al
    call    near 0x546C
    mov     byte [si], 0x00
    mov     byte [si+0x03], 0x00
    mov     al, 0x4F
    out     0x80, al
    call    near 0x53C5
    inc     bx
    db      0x8B, 0xEB                 ; mov bp, bx
    mov     al, 0x50
    out     0x80, al
    call    near 0x1C05
    pop     dx
    push    bx
    db      0x2E, 0xA0, 0x0C, 0xB5    ; mov al, [cs:0B50Ch]
    call    near 0x8300
    jne     short bios_post_memory_controller_probe_next
    mov     word [0x0013], 0xBA98
bios_post_memory_controller_probe_next:
    mov     byte [si], 0x0F
    mov     byte [si+0x03], 0x00
    mov     al, 0x51
    out     0x80, al
    call    near 0x53C5
    pop     dx
    pop     bp
    mov     al, 0x52
    out     0x80, al
bios_post_memory_controller_set_map:
    shl     dx, 0x06
    cmp     bx, 0x03FF
    jbe     short bios_post_memory_controller_map_size_ready
    mov     bx, 0x03FF
bios_post_memory_controller_map_size_ready:
    shl     bx, 0x06
    mov     [0x0013], dx
    db      0x8A, 0xE3                 ; mov ah, bl
    mov     al, 0xB0
    call    near 0xEE9D
    db      0x8A, 0xE7                 ; mov ah, bh
    mov     al, 0xB1
    call    near 0xEE9D
    pusha
    db      0x8B, 0xC4                 ; mov ax, sp
    mov     [0x0067], ax
    mov     ax, 0x038F
    call    near 0xEE9D
    call    near 0xF5A9
    mov     al, 0x53
    out     0x80, al
    db      0x2E, 0xF6, 0x06, 0x81, 0x82, 0x40 ; test byte [cs:8281h],40h
    je      short bios_post_memory_controller_real_mode
    jmp     near 0x8AD6
bios_post_memory_controller_real_mode:
    jmp     near 0xF068
bios_post_memory_controller_resume:
    mov     ax, [0x0067]
    db      0x8B, 0xE0                 ; mov sp, ax
    mov     al, 0x54
    out     0x80, al
    popa
    mov     al, 0x55
    out     0x80, al
    call    near 0x8AD2
    call    near 0xF66E
    jne     short bios_post_memory_controller_error
    mov     al, 0x56
    out     0x80, al
    call    near 0xF419
    mov     al, 0x57
    out     0x80, al
    call    near 0x1C06
    mov     al, 0x58
    out     0x80, al
    call    near bios_post_video_clear_helper
    mov     si, 0x7CA0
    call    near 0xF52E
    mov     al, 0x59
    out     0x80, al
    mov     al, [0x0012]
    test    al, 0x20
    jne     short bios_post_memory_controller_finish
    mov     al, 0xFE
    out     0x21, al
    sti
bios_post_memory_controller_finish:
    jmp     near 0xE2C6
bios_post_memory_controller_error:
    jmp     near 0x50DB

; F000:52C7 — clear the active text row and restore the cursor position.
bios_post_video_clear_helper:
    mov     dx, [0x0069]
    mov     ah, 0x02
    mov     bh, 0x00
    int     0x10
    mov     cx, 0x0050
bios_post_video_clear_loop:
    mov     ax, 0x0E20
    int     0x10
    loop    bios_post_video_clear_loop
    mov     ah, 0x02
    int     0x10
    ret

; F000:52E0 — print AX as an unsigned decimal value.
bios_post_print_decimal:
    mov     cx, 0x0006
    db      0x33, 0xD2                 ; xor dx, dx
bios_post_print_decimal_shift:
    shl     ax, 1
    rcl     dx, 1
    loop    bios_post_print_decimal_shift
    mov     cx, 0x000A
    jmp     short bios_post_print_decimal_divide
bios_post_print_decimal_recurse:
    db      0x33, 0xD2                 ; xor dx, dx
bios_post_print_decimal_divide:
    div     cx
    db      0x0B, 0xC0                 ; or ax, ax
    je      short bios_post_print_decimal_digit
    push    dx
    call    near bios_post_print_decimal_recurse
    pop     dx
bios_post_print_decimal_digit:
    db      0x8A, 0xC2                 ; mov al, dl
    or      al, 0x30
    call    near 0xF53C
    ret

%if ($ - rom_start) != 0x5305
    %error "POST memory/controller continuation must end at 5305h"
%endif

; F000:5305 — byte/word memory address-pattern probe.
bios_post_memory_word_probe:
    mov     [si], al
    mov     [si+0x03], ah
bios_post_memory_word_probe_retry:
    db      0x8C, 0xC1                 ; mov cx, es
    mov     es, cx
    db      0x26, 0xC7, 0x05, 0xAA, 0x55 ; mov word es:[di],55AAh
    push    ax
    pop     ax
    db      0x26, 0xC7, 0x45, 0x02, 0x55, 0xAA ; mov word es:[di+2],AA55h
    push    ax
    pop     ax
    db      0x26, 0x81, 0x3D, 0xAA, 0x55 ; cmp word es:[di],55AAh
    jne     short bios_post_memory_word_probe_next
    push    ax
    pop     ax
    db      0x26, 0x81, 0x7D, 0x02, 0x55, 0xAA ; cmp word es:[di+2],AA55h
    jne     short bios_post_memory_word_probe_next
    push    ds
    mov     cx, 0x0038
    mov     ds, cx
    cmp     word [0x0000], 0x55AA
    pop     ds
    je      short bios_post_memory_word_probe_next
    inc     byte [si]
    jne     short bios_post_memory_word_probe_retry
    inc     byte [si+0x03]
    jne     short bios_post_memory_word_probe_retry
bios_post_memory_word_probe_next:
    mov     al, [si]
    mov     ah, [si+0x03]
    ret

; F000:534C — walk address bits, writing and verifying the selected byte.
bios_post_memory_byte_probe:
    mov     [si], al
    mov     [si+0x03], ah
bios_post_memory_byte_probe_retry:
    db      0x8C, 0xC1                 ; mov cx, es
    mov     es, cx
    stc
bios_post_memory_byte_probe_write:
    db      0x26, 0x88, 0x05           ; mov es:[di], al
    dec     al
    rcr     di, 1
    jae     short bios_post_memory_byte_probe_write
    sub     byte [si], 0x01
    jae     short bios_post_memory_byte_probe_compare
    dec     byte [si+0x03]
bios_post_memory_byte_probe_compare:
    db      0x3A, 0x1C                 ; cmp bl, [si]
    jne     short bios_post_memory_byte_probe_retry
    db      0x3A, 0x7C, 0x03           ; cmp bh, [si+3]
    jne     short bios_post_memory_byte_probe_retry
    ret

%if ($ - rom_start) != 0x5371
    %error "POST byte/word memory probes must end at 5371h"
%endif

; F000:5371 — increment the candidate address and test address-line aliases.
bios_post_memory_address_probe:
    inc     dx
    add     byte [si], 0x01
    jae     short bios_post_memory_address_value_ready
    inc     byte [si+0x03]
bios_post_memory_address_value_ready:
    db      0x3A, 0x1C                 ; cmp bl, [si]
    jne     short bios_post_memory_address_test_aliases
    db      0x3A, 0x7C, 0x03           ; cmp bh, [si+3]
    je      short bios_post_memory_address_done
bios_post_memory_address_test_aliases:
    db      0x8C, 0xC1                 ; mov cx, es
    mov     es, cx
    mov     di, 0x0001
bios_post_memory_address_alias_loop:
    inc     al
    db      0x26, 0x30, 0x05           ; xor es:[di], al
    jne     short bios_post_memory_address_done
    rcl     di, 1
    jae     short bios_post_memory_address_alias_loop
    inc     al
    db      0x26, 0x30, 0x05           ; xor es:[di], al
    jne     short bios_post_memory_address_done
    call    near bios_post_memory_readback
    jmp     short bios_post_memory_address_probe
bios_post_memory_address_done:
    dec     dx
    call    near bios_post_memory_readback
    ret

; F000:53A6 — exercise reads and writes at ES:0000 and ES:0002.
bios_post_memory_readback:
    push    ax
    push    di
    db      0x33, 0xFF                 ; xor di, di
    db      0x26, 0x8B, 0x05           ; mov ax, es:[di]
    db      0x26, 0x89, 0x05           ; mov es:[di], ax
    db      0x26, 0x8B, 0x45, 0x02    ; mov ax, es:[di+2]
    db      0x26, 0x89, 0x45, 0x02    ; mov es:[di+2], ax
    db      0x26, 0x8B, 0x05           ; mov ax, es:[di]
    db      0x26, 0x8B, 0x45, 0x02    ; mov ax, es:[di+2]
    call    near 0xF5A9
    pop     di
    pop     ax
    ret

%if ($ - rom_start) != 0x53C5
    %error "POST address-alias probe helpers must end at 53C5h"
%endif

; F000:53C5 — memory-controller/8042-assisted RAM probe coordinator.
bios_post_memory_controller_probe:
    db      0x33, 0xDB                 ; xor bx, bx
    db      0x0B, 0xD2                 ; or dx, dx
    je      short bios_post_memory_controller_probe_done
    cmp     word [0x0013], 0xFEDC
    je      short bios_post_memory_controller_probe_retry
    call    near 0x5434
    cmp     word [0x0013], 0xBA98
    je      short bios_post_memory_controller_probe_retry
bios_post_memory_controller_probe_poll:
    call    near 0x5448
    je      short bios_post_memory_controller_probe_retry
    call    near 0x5513
    call    near 0xF5A9
    push    bx
    call    near 0x552A
    pop     bx
    jne     short bios_post_memory_controller_probe_error
    in      al, 0x61
    test    al, 0xC0
    je      short bios_post_memory_controller_clear
    db      0x2E, 0xA0, 0x0E, 0xB5    ; mov al, [cs:0B50Eh]
    call    near 0x8300
    jne     short bios_post_memory_controller_probe_error
bios_post_memory_controller_clear:
    call    near 0x5520
    inc     bx
    call    near 0x546C
    dec     dx
    jne     short bios_post_memory_controller_probe_poll
bios_post_memory_controller_probe_finish:
    call    near 0xF5A9
    call    near 0x543D
bios_post_memory_controller_probe_done:
    ret
bios_post_memory_controller_probe_retry:
    call    near 0x5448
    call    near 0x5513
    call    near 0x5520
    inc     bx
    call    near 0x546C
    dec     dx
    jne     short bios_post_memory_controller_probe_retry
    jmp     short bios_post_memory_controller_probe_finish
bios_post_memory_controller_probe_error:
    push    bx
    mov     bx, 0x0003
    call    near 0x5F8E
    pop     bx
    cli
bios_post_memory_controller_probe_error_wait:
    mov     al, [0x0012]
    test    al, 0x20
    je      short bios_post_memory_controller_probe_error_wait
%if ($ - rom_start) != 0x5434
    %error "POST memory-controller probe coordinator must end at 5434h"
%endif

; F000:5434 — enable the 8042 keyboard interface.
bios_post_8042_enable_keyboard:
    mov     al, 0xAE
    call    near 0xF635
    call    near 0xF659
    ret

; F000:543D — disable the 8042 keyboard interface and return its data byte.
bios_post_8042_disable_keyboard:
    mov     al, 0xAD
    call    near 0xF635
    call    near 0xF659
    in      al, 0x60
    ret

; F000:5448 — consume the 8042 response and update the CMOS/controller marker.
bios_post_memory_controller_8042_response:
    in      al, 0x60
    cmp     al, 0x01
    je      short bios_post_8042_response_mark
    cmp     al, 0x53
    jne     short bios_post_8042_response_check
    mov     ax, 0x8E8E
    call    near 0xEE94
    or      al, 0x01
    xchg    al, ah
    call    near 0xEE9D
bios_post_8042_response_mark:
    mov     word [0x0013], 0xFEDC
bios_post_8042_response_check:
    cmp     word [0x0013], 0xFEDC
    ret

; F000:546C — preserve the real-mode register frame across the chipset gate.
bios_post_chipset_mode_gate:
    pusha
    db      0x8B, 0xC4                 ; mov ax, sp
    mov     [0x0067], ax
    mov     ax, 0x068F
    call    near 0xEE9D
    db      0x2E, 0xF6, 0x06, 0x81, 0x82, 0x40 ; test byte [cs:8281h],40h
    je      short bios_post_chipset_mode_real_mode
    jmp     near 0x8AD6
bios_post_chipset_mode_real_mode:
    jmp     near 0xF068
bios_post_chipset_mode_resume:
    mov     ax, [0x0067]
    db      0x8B, 0xE0                 ; mov sp, ax
    call    near 0x5572
    mov     al, 0x0D
    call    near 0xF53C
    popa
    ret

; F000:5494 — report the selected memory size, then invoke INT 15h/AH=89h.
bios_post_memory_size_report:
    pusha
    db      0x8B, 0xC3                 ; mov ax, bx
    db      0x03, 0xC5                 ; add ax, bp
    push    ax
    cmp     ax, 0x061B
    jae     short bios_post_memory_size_report_skip_padding
    mov     cx, 0x0001
    cmp     ax, 0x009D
    jae     short bios_post_memory_size_report_padding
    mov     cl, 0x02
    cmp     al, 0x10
    jae     short bios_post_memory_size_report_padding
    mov     cl, 0x03
    cmp     al, 0x02
    jae     short bios_post_memory_size_report_padding
    mov     cl, 0x04
bios_post_memory_size_report_padding:
    mov     al, 0x30
    call    near 0xF53C
    loop    bios_post_memory_size_report_padding
bios_post_memory_size_report_skip_padding:
    pop     ax
    call    near bios_post_print_decimal
    mov     si, 0x7ADC
    call    near 0xF52E
    mov     ax, 0x028F
    call    near 0xEE9D
    mov     si, 0x0600
    mov     bx, 0x0800
    mov     ah, 0x89
    int     0x15
    jne     short bios_post_memory_size_report_error
    call    near 0x5506
    mov     ax, 0x0040
    mov     es, ax
    popa
    ret
bios_post_memory_size_report_error:
    jmp     near 0x50DB

; F000:54E5 — position the cursor and optionally print the memory-test marker.
bios_post_memory_status_marker:
    mov     dx, [0x0069]
    mov     bh, 0x00
    mov     ah, 0x02
    int     0x10
    db      0x2E, 0xA0, 0x0F, 0xB5    ; mov al, [cs:0B50Fh]
    call    near 0x8300
    je      short bios_post_memory_status_restore_cursor
    mov     si, 0x7C7C
    call    near 0xF52E
bios_post_memory_status_restore_cursor:
    db      0x80, 0xEE, 0x02           ; sub dh, 2
    mov     ah, 0x02
    int     0x10
    ret

; F000:5506 — restore the PIC mask and enable interrupts when permitted.
bios_post_enable_interrupts:
    mov     al, [0x0012]
    test    al, 0x20
    jne     short bios_post_enable_interrupts_done
    mov     al, 0xFE
    out     0x21, al
    sti
bios_post_enable_interrupts_done:
    ret

; F000:5513 — advance the 32-bit probe address stored at DS:SI.
bios_post_advance_probe_address:
    add     byte [si], 0x01
    jae     short bios_post_advance_probe_address_done
    inc     byte [si+0x03]
bios_post_advance_probe_address_done:
    db      0x8C, 0xC1                 ; mov cx, es
    mov     es, cx
    ret

%if ($ - rom_start) != 0x5520
    %error "POST 8042, chipset-gate and memory-size helpers must end at 5520h"
%endif

; F000:5520 — next native POST helper begins immediately below.

; F000:5520 — clear all 64 KiB at ES:0000h.
bios_post_clear_64k:
    db      0x33, 0xC0                 ; xor ax, ax
    db      0x33, 0xFF                 ; xor di, di
    mov     cx, 0x8000
    rep     stosw
    ret

; F000:552A — fill and verify 64 KiB with diagnostic patterns.
bios_post_memory_pattern_test:
    mov     bx, 0x8000
bios_post_memory_pattern_8080:
    mov     ax, 0x8080
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    rep     stosw
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    repz    scasw
    jne     short bios_post_memory_pattern_failed
    mov     ax, 0x5555
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    rep     stosw
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    repz    scasw
    jne     short bios_post_memory_pattern_failed
    mov     ax, 0x3333
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    rep     stosw
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    repz    scasw
    jne     short bios_post_memory_pattern_failed
    mov     ax, 0x0000
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    rep     stosw
    db      0x8B, 0xCB                 ; mov cx, bx
    db      0x33, 0xFF                 ; xor di, di
    repz    scasw
    jne     short bios_post_memory_pattern_failed
bios_post_memory_pattern_failed:
    ret

; F000:5572 — optional PIT channel-2 speaker/timing signal.
bios_post_pit_signal:
    mov     al, [cs:0xB50D]
    call    near 0x8300
    jne     short bios_post_pit_signal_program
    mov     cx, 0x003F
bios_post_pit_signal_delay:
    loop    bios_post_pit_signal_delay
    ret
bios_post_pit_signal_program:
    mov     al, 0xB6
    out     0x43, al
    db      0x32, 0xC0                 ; xor al, al
    db      0xE3, 0x00                 ; jcxz $+2
    db      0xE3, 0x00                 ; jcxz $+2
    out     0x42, al
    db      0xE3, 0x00                 ; jcxz $+2
    db      0xE3, 0x00                 ; jcxz $+2
    out     0x42, al
    in      al, 0x61
    or      al, 0x03
    db      0xE3, 0x00                 ; jcxz $+2
    db      0xE3, 0x00                 ; jcxz $+2
    out     0x61, al
    mov     cx, 0x003F
bios_post_pit_signal_hold:
    loop    bios_post_pit_signal_hold
    and     al, 0xFC
    out     0x61, al
    ret

%if ($ - rom_start) != 0x55A7
    %error "POST memory pattern and PIT helpers must end at 55A7h"
%endif

incbin  "ami486.bin", ($ - rom_start), (0x8280 - ($ - rom_start)) ; inherited byte 55A7h and CP437 glyph/data tables through 827Fh
    db      0x2F, 0x00, 0xE7, 0x03, 0x00, 0x00, 0x12, 0x00

; F000:82D0 — original POST callback vector table.
; CS:82DA is the active POST hook and must resolve to the stock JMP-DI
; trampoline at F000:19AB. The surrounding entries are also consumed by
; the POST/CMOS dispatch paths.
incbin  "ami486.bin", ($ - rom_start), (0x82D0 - ($ - rom_start)) ; inherited reference bytes up to 82D0h
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
incbin  "ami486.bin", ($ - rom_start), (0x8400 - ($ - rom_start)) ; inherited reference bytes up to 8400h
bios_cmos_8e_extended_entry:
    test    byte [cs:0x8280], 0x40
    jnz     short bios_cmos_8e_read
    JMP_ABS 0xD90D

bios_cmos_8e_read:
    mov     al, 0x8E
    nop
    mov     sp, 0x8414
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0x8414 - ($ - rom_start)) ; inherited reference bytes up to 8414h
bios_cmos_8e_initial_read_return:
    dw      0x8416
bios_cmos_8e_initial_read_continue:
    test    al, 0xC0
    jz      short bios_cmos_8e_extended_entry+8
    and     bp, 0xFFC7
    mov     al, 0x8E
    mov     cx, 0x0072
    db      0x32, 0xE4                 ; xor ah, ah
bios_cmos_8e_clear_iteration:
    mov     sp, 0x842A
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0x842A - ($ - rom_start)) ; inherited reference bytes up to 842Ah
bios_cmos_8e_clear_return:
    dw      0x842C
bios_cmos_8e_clear_continue:
    inc     al
    loop    bios_cmos_8e_clear_iteration

; The loop's first iteration enters the helper body at 8424h.
incbin  "ami486.bin", ($ - rom_start), (0x8430 - ($ - rom_start)) ; inherited reference bytes up to 8430h
bios_cmos_8e_restore_setup:
    mov     al, 0x8E
    mov     cx, 0x0032
    mov     si, 0x820E
bios_cmos_8e_restore_loop:
    db      0x8A, 0xE0                 ; mov ah, al
    cs lodsb
    xchg    ah, al
    mov     sp, 0x8444
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0x8444 - ($ - rom_start)) ; inherited reference bytes up to 8444h
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

incbin  "ami486.bin", ($ - rom_start), (0x8460 - ($ - rom_start)) ; inherited reference bytes up to 8460h
bios_cmos_8e_rom_table_read_return:
    dw      0x8462
bios_cmos_8e_rom_table_read_continue:
    mov     ah, [cs:si+2]
    mov     dl, [cs:si+1]
    db      0x22, 0xE2                 ; and ah, dl
    not     dl
    db      0x22, 0xC2                 ; and al, dl
    db      0x0A, 0xE0                 ; or ah, al
    mov     al, [cs:si]
    or      al, 0x80
    nop
    mov     sp, 0x847E
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0x847E - ($ - rom_start)) ; inherited reference bytes up to 847Eh
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

incbin  "ami486.bin", ($ - rom_start), (0x849E - ($ - rom_start)) ; inherited reference bytes up to 849Eh
bios_cmos_8e_descriptor_read_return:
    dw      0x84A0
bios_cmos_8e_descriptor_read_continue:
    mov     ah, [cs:si+2]
    mov     dl, [cs:si+1]
    db      0x22, 0xE2                 ; and ah, dl
    not     dl
    db      0x22, 0xC2                 ; and al, dl
    db      0x0A, 0xE0                 ; or ah, al
    mov     al, [cs:si]
    or      al, 0x80
    nop
    mov     sp, 0x84BC
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0x84BC - ($ - rom_start)) ; inherited reference bytes up to 84BCh
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
incbin  "ami486.bin", ($ - rom_start), (0x88CE - ($ - rom_start)) ; inherited reference bytes up to 88CEh
bios_8042_clear_entry:
    mov     cx, 0x0100
bios_8042_delay:
    loop    bios_8042_delay
    mov     ax, cs
    mov     ss, ax
    smsw    ax
    test    al, 0x01
    jnz     short bios_8042_reset_reentry
    db      0x0A, 0xE4                 ; or ah, ah
    jnz     short bios_8042_set_ah_zero
    cmp     dh, 0x04
    jnz     short bios_8042_set_ah_zero
    nop
    mov     sp, 0x88EE
    jmp     short bios_8042_arithmetic_probe
    nop

; The CMOS helper RET consumes this inline word and resumes at 88F0h.
incbin  "ami486.bin", ($ - rom_start), (0x88EE - ($ - rom_start)) ; inherited reference bytes up to 88EEh
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
incbin  "ami486.bin", ($ - rom_start), (0x890E - ($ - rom_start)) ; inherited reference bytes up to 890Eh
bios_8042_cmos_read_return:
    dw      0x8910
bios_8042_cmos_read_continue:
    and     al, 0xF1
    db      0x0A, 0xE0                 ; or ah, al
    mov     al, 0xB3
    mov     sp, 0x891C
    JMP_ABS 0xEE9D

; EE9Dh returns to 891Eh; that continuation restarts POST at D60Fh.
incbin  "ami486.bin", ($ - rom_start), (0x891C - ($ - rom_start)) ; inherited reference bytes up to 891Ch
bios_8042_cmos_write_return:
    dw      0x891E
bios_8042_reset_reentry:
    JMP_ABS 0xD60F

; The crafted stack at 88EEh returns here after the arithmetic/flags probe.
bios_8042_arithmetic_probe:
    db      0x33, 0xC0                 ; xor ax, ax
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
    db      0x32, 0xC9                 ; xor cl, cl
    mov     ax, 0xC2C2
    mov     sp, 0x893C
    JMP_ABS 0x8DCF

incbin  "ami486.bin", ($ - rom_start), (0x893C - ($ - rom_start)) ; inherited reference bytes up to 893Ch
bios_ali_read_c2_return:
    dw      0x893E
bios_ali_read_c2_continue:
    db      0x8A, 0xD8                 ; mov bl, al
    or      al, 0x04
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0x894A
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x894A - ($ - rom_start)) ; inherited reference bytes up to 894Ah
bios_ali_write_c2_return:
    dw      0x894C
bios_ali_write_c2_continue:
    mov     sp, 0x8952
    JMP_ABS 0x8DCF

incbin  "ami486.bin", ($ - rom_start), (0x8952 - ($ - rom_start)) ; inherited reference bytes up to 8952h
bios_ali_read_c3_return:
    dw      0x8954
bios_ali_read_c3_continue:
    test    al, 0x04
    jz      short bios_ali_c2_set_flag
    db      0x8A, 0xE3                 ; mov ah, bl
    and     ah, 0xFB
    mov     al, 0xC2
    nop
    mov     sp, 0x8966
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x8966 - ($ - rom_start)) ; inherited reference bytes up to 8966h
bios_ali_write_c2_second_return:
    dw      0x8968
bios_ali_write_c2_second_continue:
    mov     sp, 0x896E
    JMP_ABS 0x8DCF

incbin  "ami486.bin", ($ - rom_start), (0x896E - ($ - rom_start)) ; inherited reference bytes up to 896Eh
bios_ali_read_c2_second_return:
    dw      0x8970
bios_ali_read_c2_second_continue:
    test    al, 0x04
    jz      short bios_ali_c2_common_write
bios_ali_c2_set_flag:
    or      cl, 0x02
bios_ali_c2_common_write:
    db      0x8A, 0xE3                 ; mov ah, bl
    mov     al, 0xC2
    nop
    mov     sp, 0x8982
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x8982 - ($ - rom_start)) ; inherited reference bytes up to 8982h
bios_ali_write_c3_return:
    dw      0x8984
bios_ali_write_c3_continue:
    mov     ax, 0xC3C3
    nop
    mov     sp, 0x898E
    JMP_ABS 0x8DCF

incbin  "ami486.bin", ($ - rom_start), (0x898E - ($ - rom_start)) ; inherited reference bytes up to 898Eh
bios_ali_read_c3_second_return:
    dw      0x8990
bios_ali_read_c3_second_continue:
    db      0x8A, 0xD8                 ; mov bl, al
    or      al, 0x02
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0x899C
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x89A4 - ($ - rom_start)) ; inherited reference bytes up to 89A4h
bios_ali_read_c3_third_return:
    dw      0x89A6
bios_ali_read_c3_third_continue:
    test    al, 0x02
    jz      short 0x89C6
    db      0x8A, 0xE3                 ; mov ah, bl
    and     ah, 0xFD
    mov     al, 0xC3
    nop
    mov     sp, 0x89B8
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x89B8 - ($ - rom_start)) ; inherited reference bytes up to 89B8h
bios_ali_write_c3_second_return:
    dw      0x89BA
bios_ali_write_c3_second_continue:
    mov     sp, 0x89C0
    JMP_ABS 0x8DCF

incbin  "ami486.bin", ($ - rom_start), (0x89C0 - ($ - rom_start)) ; inherited reference bytes up to 89C0h
bios_ali_read_c3_fourth_return:
    dw      0x89C2
bios_ali_read_c3_fourth_continue:
    test    al, 0x02
    jz      short bios_ali_c3_fourth_no_bit1
    or      cl, 0x01
bios_ali_c3_fourth_no_bit1:
    db      0x8A, 0xE3                 ; mov ah, bl
    mov     al, 0xC3
    nop
    mov     sp, 0x89D4
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x89D4 - ($ - rom_start)) ; inherited reference bytes up to 89D4h
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

incbin  "ami486.bin", ($ - rom_start), (0x89EC - ($ - rom_start)) ; inherited reference bytes up to 89ECh
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
    db      0xFF, 0xE7                 ; jmp di

; ---------------------------------------------------------------------------
; F000:8A04 — reset-mode dispatch.
incbin  "ami486.bin", ($ - rom_start), (0x8A04 - ($ - rom_start)) ; inherited reference bytes up to 8A04h
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
incbin  "ami486.bin", ($ - rom_start), (0x8A20 - ($ - rom_start)) ; inherited reference bytes up to 8A20h
bios_cmos_dispatch:
    db      0x8B, 0xC6                 ; mov ax, si
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
    db      0x8A, 0xD0                 ; mov dl, al
    ror     eax, 16
    db      0x8B, 0xD8                 ; mov bx, ax
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
    db      0x8B, 0xC3                 ; mov ax, bx
    ror     eax, 16
bios_cmos_post_55:
    or      al, 0xFF
    JMP_ABS 0xD655
    JMP_ABS 0xD74C

; ---------------------------------------------------------------------------
; F000:8A78 — dynamic POST hook and stack-threaded ALi setup continuation.
incbin  "ami486.bin", ($ - rom_start), (0x8A78 - ($ - rom_start)) ; inherited reference bytes up to 8A78h
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

incbin  "ami486.bin", ($ - rom_start), (0x8A8E - ($ - rom_start)) ; inherited reference bytes up to 8A8Eh
bios_post_ali_mode_return:
    dw      0x8A90
bios_post_ali_mode_continue:
    mov     ax, 0xB3B3
    nop
    mov     sp, 0x8A9A
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0x8A9A - ($ - rom_start)) ; inherited reference bytes up to 8A9Ah
bios_post_cmos_b3_read_return:
    dw      0x8A9C
bios_post_cmos_b3_read_continue:
    and     al, 0xFE
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0x8AA6
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0x8AA6 - ($ - rom_start)) ; inherited reference bytes up to 8AA6h
bios_post_cmos_b3_write_return:
    dw      0x8AA8
bios_post_cmos_b3_write_continue:
    mov     ax, 0xC503
    nop
    mov     sp, 0x8AB2
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x8AB2 - ($ - rom_start)) ; inherited reference bytes up to 8AB2h
bios_post_ali_1313_write_return:
    dw      0x8AB4
bios_post_ali_1313_write_continue:
    mov     ax, 0x1313
    nop
    mov     sp, 0x8ABE
    JMP_ABS 0x8DCF

incbin  "ami486.bin", ($ - rom_start), (0x8ABE - ($ - rom_start)) ; inherited reference bytes up to 8ABEh
bios_post_ali_1313_read_return:
    dw      0x8AC0
bios_post_ali_1313_read_continue:
    and     al, 0x3F
    xchg    ah, al
    mov     sp, 0x8ACA
    JMP_ABS 0x8DDC

incbin  "ami486.bin", ($ - rom_start), (0x8ACA - ($ - rom_start)) ; inherited reference bytes up to 8ACAh
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
incbin  "ami486.bin", ($ - rom_start), (0x8AD5 - ($ - rom_start)) ; inherited reference bytes up to 8AD5h
bios_reset_keyboard_wait:
    cli
    cli
    db      0x33, 0xC9                 ; xor cx, cx
bios_keyboard_wait_busy:
    jcxz    $+2
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
incbin  "ami486.bin", ($ - rom_start), (0x8CCD - ($ - rom_start)) ; inherited reference bytes up to 8CCDh
bios_cr0_disable_cache_if_real_mode:
    smsw    ax
    test    al, 0x01
    jnz     bios_indexed_jump_di
    db      0x0A, 0xE4                 ; or ah, ah
    jnz     bios_indexed_jump_di
    mov     eax, cr0
    or      eax, 0x60000000
    mov     cr0, eax
    wbinvd
    db      0x33, 0xC0                 ; xor ax, ax
bios_indexed_jump_di:
    jmp     di

; The byte at 8CEAh is an alternate/overlapping decode byte; the reachable
; helper entry below is the verified 8CEBh stream.
incbin  "ami486.bin", ($ - rom_start), (0x8CEB - ($ - rom_start)) ; inherited reference bytes up to 8CEBh
bios_8042_wait_and_read:
    loopne  0x8D20
    leave
bios_8042_wait_input_empty_8ceb:
    jcxz    $+2
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_wait_input_empty_8ceb
    jnz     bios_8042_command_done
    db      0x8A, 0xC4                 ; mov al, ah
    out     0x64, al
    db      0x33, 0xC9                 ; xor cx, cx
bios_8042_wait_output_full:
    jcxz    $+2
    in      al, 0x64
    test    al, 0x01
    loope   bios_8042_wait_output_full
    in      al, 0x60
bios_8042_command_done:
    ret

; F000:8D09 — ALi indexed-register mode helpers.
incbin  "ami486.bin", ($ - rom_start), (0x8D09 - ($ - rom_start)) ; inherited reference bytes up to 8D09h
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

incbin  "ami486.bin", ($ - rom_start), (0x8D39 - ($ - rom_start)) ; inherited reference bytes up to 8D39h
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

incbin  "ami486.bin", ($ - rom_start), (0x8D56 - ($ - rom_start)) ; inherited reference bytes up to 8D56h
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

incbin  "ami486.bin", ($ - rom_start), (0x8D83 - ($ - rom_start)) ; inherited reference bytes up to 8D83h
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
incbin  "ami486.bin", ($ - rom_start), (0x8DCF - ($ - rom_start)) ; inherited reference bytes up to 8DCFh
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
    db      0xFF, 0xE7                 ; jmp di

; ---------------------------------------------------------------------------
; F000:D604 — reset-time POST entry and CMOS marker dispatch.
incbin  "ami486.bin", ($ - rom_start), (0xD604 - ($ - rom_start)) ; inherited reference bytes up to D604h
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
    db      0x8B, 0xF0                 ; mov si, ax
    mov     al, 0x8F
    jcxz    $+2
    out     0x70, al
    mov     al, 0
    jcxz    $+2
    jcxz    $+2
    out     0x71, al
    mov     ax, cs
    mov     ss, ax
    db      0x8B, 0xC6                 ; mov ax, si
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
    db      0x8B, 0xC6                 ; mov ax, si
    cmp     al, 0x05
    je      bios_cr0_adjust
    cmp     al, 0x09
    je      bios_cr0_adjust
    cmp     al, 0x0A
    jnz     bios_post_delay_setup
bios_cr0_adjust:
    ror     eax, 16
    db      0x8B, 0xC8                 ; mov cx, ax
    smsw    ax
    db      0x0A, 0xE4                 ; or ah, ah
    mov     eax, cr0
    jz      bios_cr0_clear_cache
    or      al, 0x10
    jmp     bios_cr0_write
bios_cr0_clear_cache:
    and     eax, 0x9FFFFFFF
bios_cr0_write:
    mov     cr0, eax
    db      0x8B, 0xC1                 ; mov ax, cx
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
incbin  "ami486.bin", ($ - rom_start), (0xD6A8 - ($ - rom_start)) ; inherited reference bytes up to D6A8h
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
    db      0x8B,0xD8, 0x8B,0xCB, 0x8B,0xD1, 0x8B,0xF2, 0x8B,0xFE, 0x8B,0xEF
    mov     es, bp
    mov     ax, es
    mov     ds, ax
    mov     ax, ds
    mov     ss, ax
    mov     ax, ss
    jmp     sp

; D6DEh — first SS:SP test stream.
incbin  "ami486.bin", ($ - rom_start), (0xD6DE - ($ - rom_start)) ; inherited reference bytes up to D6DEh
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
    db      0x0A, 0xC0                 ; or al, al
    jz      bios_post_delay_complete
bios_post_delay_loop:
    loop    bios_post_delay_loop
    dec     al
    jnz     bios_post_delay_loop

; F000:D724 — exact delay completion and POST checkpoint 03h.
incbin  "ami486.bin", ($ - rom_start), (0xD724 - ($ - rom_start)) ; inherited reference bytes up to D724h
bios_post_delay_complete:
    test    byte [cs:0x8281], 0x40
    jnz     bios_post_checkpoint_03
    smsw    ax
    db      0x0A, 0xE4                 ; or ah, ah
    jz      bios_post_checkpoint_03
    mov     eax, cr0
    or      al, 0x10
    mov     cr0, eax
bios_post_checkpoint_03:
    mov     al, 0x03
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    db      0x33, 0xED                 ; xor bp, bp
    mov     ds, bp
    mov     es, bp
    JMP_ABS 0x8A75

; F000:D74C — POST checkpoint 04h and 8042/reset-state dispatch.
bios_post_checkpoint_04:
    mov     al, 0x04
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    db      0x33, 0xC0                 ; xor ax, ax
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
incbin  "ami486.bin", ($ - rom_start), (0xD777 - ($ - rom_start)) ; inherited reference bytes up to D777h
bios_post_memory_checksum:
    mov     al, 0x06
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    db      0x33, 0xC0                 ; xor ax, ax
    mov     ds, ax
    mov     es, ax
    db      0x33, 0xDB                 ; xor bx, bx
    mov     cx, 0x8000
    db      0x33, 0xF6                 ; xor si, si
bios_post_checksum_loop:
    cs lodsw
    db      0x03, 0xD8                 ; add bx, ax
    loop    bios_post_checksum_loop
    jz      bios_post_8042_drain
    mov     bp, 0x0009
    JMP_ABS 0xF4A5

bios_post_8042_drain:
    db      0x33, 0xC9                 ; xor cx, cx
bios_post_8042_status:
    in      al, 0x64
    db      0x8A, 0xE0                 ; mov ah, al
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
    db      0x33, 0xFF                 ; xor di, di
    test    al, 0x01
    jz      bios_post_8042_response_wait
    dec     di
bios_post_8042_response_wait:
    nop
    mov     sp, 0xD7D8
    JMP_ABS 0xF659

incbin  "ami486.bin", ($ - rom_start), (0xD7D8 - ($ - rom_start)) ; inherited reference bytes up to D7D8h
bios_post_8042_wait_aa_return:
    dw      0xD7DA
bios_post_8042_wait_aa_continue:
    mov     al, 0x08
    out     0x80, al
    mov     sp, 0xD7E4
    JMP_ABS 0xF60F

incbin  "ami486.bin", ($ - rom_start), (0xD7E4 - ($ - rom_start)) ; inherited reference bytes up to D7E4h
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
    db      0x0B, 0xFF                 ; or di, di
    jz      bios_post_keyboard_init_done
    mov     al, 0xA1
    out     0x64, al
    mov     sp, 0xD806
    JMP_ABS 0xF659

incbin  "ami486.bin", ($ - rom_start), (0xD806 - ($ - rom_start)) ; inherited reference bytes up to D806h
bios_post_8042_a1_return:
    dw      0xD808
bios_post_8042_a1_continue:
    db      0x33, 0xC9                 ; xor cx, cx
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

incbin  "ami486.bin", ($ - rom_start), (0xD826 - ($ - rom_start)) ; inherited reference bytes up to D826h
bios_post_8042_ff_return:
    dw      0xD828
bios_post_keyboard_init_done:
    mov     al, 0x09
    out     0x80, al
    JMP_ABS 0x1AF8

; ---------------------------------------------------------------------------
; F000:D82F — first 8042 command/data exchange after POST 09h.
incbin  "ami486.bin", ($ - rom_start), (0xD82F - ($ - rom_start)) ; inherited reference bytes up to D82Fh
bios_post_8042_command_60:
    mov     al, 0x60
    out     0x64, al
    nop
    mov     sp, 0xD83A
    JMP_ABS 0xF659

incbin  "ami486.bin", ($ - rom_start), (0xD83A - ($ - rom_start)) ; inherited reference bytes up to D83Ah
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

incbin  "ami486.bin", ($ - rom_start), (0xD854 - ($ - rom_start)) ; inherited reference bytes up to D854h
bios_post_8042_command_data_return:
    dw      0xD856
incbin  "ami486.bin", ($ - rom_start), (0xD856 - ($ - rom_start)) ; inherited reference bytes up to D856h
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

incbin  "ami486.bin", ($ - rom_start), (0xD86E - ($ - rom_start)) ; inherited reference bytes up to D86Eh
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

incbin  "ami486.bin", ($ - rom_start), (0xD882 - ($ - rom_start)) ; inherited reference bytes up to D882h
bios_post_cmos_8f_55_return:
    dw      0xD884
bios_post_cmos_8f_55_continue:
    mov     al, 0x0D
    out     0x80, al
    mov     ax, 0x558F
    nop
    mov     sp, 0xD892
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0xD892 - ($ - rom_start)) ; inherited reference bytes up to D892h
bios_post_cmos_8f_55_read_return:
    dw      0xD894
bios_post_cmos_8f_55_read_continue:
    mov     sp, 0xD89A
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0xD89A - ($ - rom_start)) ; inherited reference bytes up to D89Ah
bios_post_cmos_8f_55_compare_return:
    dw      0xD89C
bios_post_cmos_8f_55_compare_continue:
    db      0x32, 0xC4                 ; xor al, ah
    jnz     short bios_post_cmos_8f_mismatch
    mov     ax, 0xAA8F
    nop
    mov     sp, 0xD8AA
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0xD8AA - ($ - rom_start)) ; inherited reference bytes up to D8AAh
bios_post_cmos_8f_aa_write_return:
    dw      0xD8AC
bios_post_cmos_8f_aa_write_continue:
    mov     sp, 0xD8B2
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0xD8B2 - ($ - rom_start)) ; inherited reference bytes up to D8B2h
bios_post_cmos_8f_aa_read_return:
    dw      0xD8B4
bios_post_cmos_8f_aa_read_continue:
    db      0x32, 0xC4                 ; xor al, ah
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

incbin  "ami486.bin", ($ - rom_start), (0xD8CA - ($ - rom_start)) ; inherited reference bytes up to D8CAh
bios_post_cmos_8e_read_return:
    dw      0xD8CC
bios_post_cmos_8e_read_continue:
    db      0x0A, 0xC0                 ; or al, al
    mov     ax, 0x8E8E
    nop
    mov     sp, 0xD8D8
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0xD8D8 - ($ - rom_start)) ; inherited reference bytes up to D8D8h
bios_post_cmos_8e_flags_return:
    dw      0xD8DA
bios_post_cmos_8e_flags_continue:
    js      short bios_post_cmos_8e_negative
    or      bp, 0x0008
    or      al, 0xDC
    jmp     short bios_post_cmos_8e_flags_done
bios_post_cmos_8e_negative:
    db      0x0A, 0xC0                 ; or al, al
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
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0xD904
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0xD904 - ($ - rom_start)) ; inherited reference bytes up to D904h
bios_post_cmos_8e_write_return:
    dw      0xD906
bios_post_cmos_8e_write_continue:
    mov     al, 0x0F
    out     0x80, al
    JMP_ABS 0x8400

; Separate D90Dh POST entry: CMOS 8Bh read/modify/write sequence.
incbin  "ami486.bin", ($ - rom_start), (0xD90D - ($ - rom_start)) ; inherited reference bytes up to D90Dh
bios_post_cmos_8b_update:
    mov     al, 0x10
    out     0x80, al
    mov     ax, 0x8B8B
    mov     sp, 0xD91A
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0xD91A - ($ - rom_start)) ; inherited reference bytes up to D91Ah
bios_post_cmos_8b_read_return:
    dw      0xD91C
bios_post_cmos_8b_read_continue:
    and     al, 0x07
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0xD926
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0xD926 - ($ - rom_start)) ; inherited reference bytes up to D926h
bios_post_cmos_8c_read_return:
    dw      0xD928
bios_post_cmos_8c_read_continue:
    mov     al, 0x8C
    mov     sp, 0xD930
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0xD930 - ($ - rom_start)) ; inherited reference bytes up to D930h
bios_post_cmos_8a_read_return:
    dw      0xD932
bios_post_cmos_8a_read_continue:
    mov     ax, 0x8A8A
    nop
    mov     sp, 0xD93C
    JMP_ABS 0xEE94

incbin  "ami486.bin", ($ - rom_start), (0xD93C - ($ - rom_start)) ; inherited reference bytes up to D93Ch
bios_post_cmos_8a_compare_return:
    dw      0xD93E
bios_post_cmos_8a_compare_continue:
    and     al, 0x0F
    jnz     short bios_post_cmos_8a_enable_keyboard
    mov     al, 0x26
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0xD94C
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0xD94C - ($ - rom_start)) ; inherited reference bytes up to D94Ch
bios_post_keyboard_enable_return:
    dw      0xD94E
bios_post_keyboard_enable_continue:
bios_post_cmos_8a_enable_keyboard:
    mov     al, 0xAE
    out     0x64, al
    mov     sp, 0xD958
    JMP_ABS 0xF659

incbin  "ami486.bin", ($ - rom_start), (0xD958 - ($ - rom_start)) ; inherited reference bytes up to D958h
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

incbin  "ami486.bin", ($ - rom_start), (0xD96E - ($ - rom_start)) ; inherited reference bytes up to D96Eh
bios_post_cmos_8e_update_return:
    dw      0xD970
bios_post_cmos_8e_update_continue:
    or      al, 0x01
    db      0x86, 0xC4                 ; xchg ah, al
    mov     sp, 0xD97A
    JMP_ABS 0xEE9D

incbin  "ami486.bin", ($ - rom_start), (0xD97A - ($ - rom_start)) ; inherited reference bytes up to D97Ah
bios_post_keyboard_disable_return:
    dw      0xD97C
bios_post_keyboard_disable:
    mov     al, 0xAD
    out     0x64, al
    mov     sp, 0xD986
    JMP_ABS 0xF659

incbin  "ami486.bin", ($ - rom_start), (0xD986 - ($ - rom_start)) ; inherited reference bytes up to D986h
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

incbin  "ami486.bin", ($ - rom_start), (0xD9A0 - ($ - rom_start)) ; inherited reference bytes up to D9A0h
bios_post_chipset_io_return:
    dw      0xD9A2
bios_post_chipset_io_continue:
    mov     al, 0x12
    out     0x80, al
    db      0x33, 0xC0                 ; xor ax, ax
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
    db      0x33, 0xC0                 ; xor ax, ax
    mov     es, ax
    mov     ds, ax
    mov     al, 0x13
    out     0x80, al
    JMP_ABS 0x1AFB

; F000:D9DCh — PIT channel-2 latch/readback test and channel-0 setup.
incbin  "ami486.bin", ($ - rom_start), (0xD9DC - ($ - rom_start)) ; inherited reference bytes up to D9DCh
bios_post_pit_channel2_test:
    mov     al, 0x14
    out     0x80, al
    mov     ax, cs
    mov     ss, ax
    db      0x33, 0xC0                 ; xor ax, ax
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
    db      0x8A, 0xE0                 ; mov ah, al
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
    db      0x0A, 0xC0                 ; or al, al
    jnz     short bios_post_pit_test_done
    db      0x33, 0xDB                 ; xor bx, bx
    mov     ah, 0x10
    mov     dx, 0x0061
    nop
    mov     sp, 0xDA64
    JMP_ABS 0xF598

; The F598h timing helper returns through this inline word.
incbin  "ami486.bin", ($ - rom_start), (0xDA64 - ($ - rom_start)) ; inherited reference bytes up to DA64h
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
    db      0x33, 0xC9                 ; xor cx, cx
bios_post_pit_wait_low:
    in      al, 0x61
    test    ah, al
    loopne  bios_post_pit_wait_low
    xchg    bx, cx
bios_post_pit_wait_second_high:
    in      al, 0x61
    test    ah, al
    loope   bios_post_pit_wait_second_high
    db      0x2B, 0xCB                 ; sub cx, bx
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
incbin  "ami486.bin", ($ - rom_start), (0xE05B - ($ - rom_start)) ; inherited reference bytes up to E05Bh
reset_gateway:
    jmp     near bios_post_entry
reset_gateway_end:
%if (reset_gateway_end - reset_gateway) != 3
    %error "Unexpected reset gateway size"
%endif

; ---------------------------------------------------------------------------
; F000:E93Ch — PIT channel-2 transition wait used by POST speaker diagnostics.
incbin  "ami486.bin", ($ - rom_start), (0xE93C - ($ - rom_start)) ; inherited reference bytes up to E93Ch
bios_post_pit_transition_wait:
    push    ax
    mov     al, [cs:0x8285]
    db      0x0A, 0xC0                 ; or al, al
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
incbin  "ami486.bin", ($ - rom_start), (0xEE94 - ($ - rom_start)) ; inherited reference bytes up to EE94h
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
incbin  "ami486.bin", ($ - rom_start), (0xEEE7 - ($ - rom_start)) ; inherited reference bytes up to EEE7h
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
    db      0x8A, 0xC3                 ; mov al, bl
    out     0xA1, al
    jcxz    $+2
    jcxz    $+2
    db      0x8A, 0xC7                 ; mov al, bh
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
incbin  "ami486.bin", ($ - rom_start), (0xF4A5 - ($ - rom_start)) ; inherited reference bytes up to F4A5h
bios_post_fatal_error:
    db      0x8B, 0xD5                 ; mov dx, bp
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
    db      0x8B, 0xC6                 ; mov ax, si
    out     0x81, al
    jcxz    $+2
    jcxz    $+2
    db      0x8A, 0xC4                 ; mov al, ah
    out     0x82, al
    jcxz    $+2
    jcxz    $+2
    db      0x8B, 0xC7                 ; mov ax, di
    out     0x83, al
    jcxz    $+2
    jcxz    $+2
    db      0x8A, 0xC4                 ; mov al, ah
    out     0x84, al
    jmp     short bios_post_fatal_error

bios_post_fatal_beep:
    mov     bx, 0x0080
    in      al, 0x61
    and     al, 0xFE
    jcxz    $+2
    jcxz    $+2
bios_post_fatal_beep_loop:
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
    db      0x33, 0xC0                 ; xor ax, ax
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
bios_post_fatal_keyboard_wait_loop:
    loop    bios_post_fatal_keyboard_wait_loop
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
bios_post_print_cs_string_loop:
    cli
    cld
    cs lodsb
    db      0x22, 0xC0                 ; and al, al
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
    db      0x33, 0xC9                 ; xor cx, cx
bios_post_wait_port_bits_clear:
    in      al, dx
    test    ah, al
    loope   bios_post_wait_port_bits_clear
    jz      short bios_post_wait_port_bits_done
    db      0x33, 0xC9                 ; xor cx, cx
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
    db      0x3A, 0xC4                 ; cmp al, ah
bios_post_8042_compare_done:
    ret

bios_post_8042_compare_data:
    call    bios_post_8042_write_data
    jnz     short bios_post_8042_compare_data_done
    call    bios_post_8042_read_response
    jz      short bios_post_8042_compare_success
    db      0x3A, 0xC4                 ; cmp al, ah
bios_post_8042_compare_data_done:
    ret

bios_post_8042_compare_success:
    db      0x0B, 0xE4                 ; or sp, sp
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
    db      0x33, 0xC9                 ; xor cx, cx
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
incbin  "ami486.bin", ($ - rom_start), (0xF60F - ($ - rom_start)) ; inherited reference bytes up to F60Fh
bios_8042_read_output:
    mov     ah, 0x0C
    db      0x33, 0xC9                 ; xor cx, cx
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
incbin  "ami486.bin", ($ - rom_start), (0xF622 - ($ - rom_start)) ; inherited reference bytes up to F622h
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
    db      0x8A, 0xE0                 ; mov ah, al
    mov     al, 0x60
    call    bios_post_8042_write_command
    ret

%if ($ - rom_start) != 0xF659
    %error "8042 command/data transaction helpers must end at F659h"
%endif

; F000:F659 — 8042 input-buffer-empty wait helper.
incbin  "ami486.bin", ($ - rom_start), (0xF659 - ($ - rom_start)) ; inherited reference bytes up to F659h
bios_8042_wait_input_empty:
    db      0x33, 0xC9                 ; xor cx, cx
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
incbin  "ami486.bin", ($ - rom_start), (0xF66A - ($ - rom_start)) ; inherited reference bytes up to F66Ah
bios_8042_a20_enable:
    mov     ah, 0xDF
    jmp     short bios_8042_a20_write
bios_8042_a20_disable:
    mov     ah, 0xDD
bios_8042_a20_write:
    db      0x33, 0xC9                 ; xor cx, cx
bios_8042_a20_wait_command:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_a20_wait_command
    mov     al, 0xD1
    out     0x64, al
    db      0x33, 0xC9                 ; xor cx, cx
bios_8042_a20_wait_data:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_a20_wait_data
    db      0x8A, 0xC4                 ; mov al, ah
    out     0x60, al
    db      0x33, 0xC9                 ; xor cx, cx
bios_8042_a20_wait_finish:
    in      al, 0x64
    test    al, 0x02
    loopne  bios_8042_a20_wait_finish
    ret

; FFFF:0000 reset vector -> F000:E05B.
incbin  "ami486.bin", ($ - rom_start), (0xFFF0 - ($ - rom_start)) ; inherited reference bytes up to FFF0h
bios_reset_vector:
    jmp     0xF000:reset_gateway

incbin  "ami486.bin", ($ - rom_start), (ROM_SIZE - ($ - rom_start)) ; inherited trailing bytes after reset vector
%if ($ - rom_start) != ROM_SIZE
    %error "Incorrect BIOS ROM size"
%endif
