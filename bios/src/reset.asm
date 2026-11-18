; Project134 — AMI486 BIOS reconstruction
; Source policy: executable code is written as NASM instructions.
; No reference-ROM machine-code byte blocks are permitted here.
; Unimplemented ROM areas use FFh erased-state fill only.

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
; F000:88CE — first 8042-clear POST branch.
; Disassembly: analysis/disasm/ami486_branches.disasm.txt
; ---------------------------------------------------------------------------
times 0x88CE - ($ - rom_start) db 0xFF
bios_8042_clear_entry:
    ; TODO: translate the verified disassembly into NASM instructions.

; ---------------------------------------------------------------------------
; F000:8A04 — reset continuation / CMOS[8Fh] path.
; ---------------------------------------------------------------------------
times 0x8A04 - ($ - rom_start) db 0xFF
bios_reset_cmos_path:
    ; TODO: translate the verified disassembly into NASM instructions.

; ---------------------------------------------------------------------------
; F000:D604 — initial POST entry.
; Disassembly: analysis/disasm/ami486_post_entry.disasm.txt
; ---------------------------------------------------------------------------
times 0xD604 - ($ - rom_start) db 0xFF
bios_post_entry:
    cli
    cld
    in      al, 0x64
    test    al, 0x04
    jnz     bios_reset_continuation
    jmp     bios_8042_clear_entry

; F000:D60F — common continuation.
bios_post_common:
    jmp     bios_ram_test_entry

; F000:D612 — alternate reset continuation.
bios_reset_continuation:
    jmp     bios_reset_cmos_path

; F000:D6DE — subsequent POST/RAM-test path.
times 0xD6DE - ($ - rom_start) db 0xFF
bios_ram_test_entry:
    ; TODO: reconstruct from disassembly; no copied opcodes.

; ---------------------------------------------------------------------------
; F000:E05B — reset gateway.
; ---------------------------------------------------------------------------
times 0xE05B - ($ - rom_start) db 0xFF
reset_gateway:
    jmp near bios_post_entry
reset_gateway_end:
%if (reset_gateway_end - reset_gateway) != 3
    %error "Unexpected reset gateway size"
%endif

; ---------------------------------------------------------------------------
; FFFF:0000 reset vector -> F000:E05B.
; ---------------------------------------------------------------------------
times 0xFFF0 - ($ - rom_start) db 0xFF
bios_reset_vector:
    jmp 0xF000:reset_gateway

times ROM_SIZE - ($ - rom_start) db 0xFF

%if ($ - rom_start) != ROM_SIZE
    %error "Incorrect BIOS ROM size"
%endif
