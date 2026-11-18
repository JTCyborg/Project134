; Project134 — AMI486 BIOS reconstruction
; Source policy: executable code is written as NASM instructions.
; No reference-ROM machine-code byte blocks are permitted here.
; Unimplemented ROM areas are erased-state fill (FFh), not copied code.

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
; Reset entry — ROM offset FFF0h, CPU starts at physical FFFFFFF0h.
; The reset vector transfers to F000:E05B.
; ---------------------------------------------------------------------------
times 0xE05B - ($ - rom_start) db 0xFF
reset_gateway:
    jmp near bios_post_entry
reset_gateway_end:
%if (reset_gateway_end - reset_gateway) != 3
    %error "Unexpected reset gateway size"
%endif

; ---------------------------------------------------------------------------
; POST entry — F000:D604.
; Disassembly source: analysis/disasm/ami486_post_entry.disasm.txt
; ---------------------------------------------------------------------------
times 0xD604 - ($ - rom_start) db 0xFF
bios_post_entry:
    cli
    cld
    in      al, 0x64
    test    al, 0x04
    jnz     bios_reset_continuation
    jmp     bios_8042_clear_entry

; F000:D60F — common continuation selected by the reset/8042 path.
bios_post_common:
    jmp     bios_ram_test_entry

bios_reset_continuation:
    jmp     bios_reset_cmos_path

; ---------------------------------------------------------------------------
; The following entry points are declared now and will be implemented from
; the disassembly in subsequent reconstruction passes. Until then their ROM
; locations remain FFh; this image is intentionally incomplete.
; ---------------------------------------------------------------------------
times 0x88CE - ($ - rom_start) db 0xFF
bios_8042_clear_entry:
    ; TODO: reconstruct instruction-by-instruction from disassembly.

times 0x8A04 - ($ - rom_start) db 0xFF
bios_reset_cmos_path:
    ; TODO: reconstruct instruction-by-instruction from disassembly.

times 0xD6DE - ($ - rom_start) db 0xFF
bios_ram_test_entry:
    ; TODO: reconstruct instruction-by-instruction from disassembly.

; ---------------------------------------------------------------------------
; Reset vector — FFFF:0000 -> F000:E05B.
; ---------------------------------------------------------------------------
times 0xFFF0 - ($ - rom_start) db 0xFF
bios_reset_vector:
    jmp     0xF000:reset_gateway

times ROM_SIZE - ($ - rom_start) db 0xFF

%if ($ - rom_start) != ROM_SIZE
    %error "Incorrect BIOS ROM size"
%endif
