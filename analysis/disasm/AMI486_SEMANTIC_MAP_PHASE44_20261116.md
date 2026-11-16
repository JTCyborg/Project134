# AMI486 semantic map — phase 44 (2026-11-16)

## Scope

This phase audits the BP and DX inputs used by the 8042 path recovered in phase 43. It checks the visible path at 5C70h–5D07h, the wrappers F651h/F622h/F635h/F644h, the only local call to 1B5Eh, and all linear-list occurrences of immediate BP mask 2000h.

ROM basis: ami486.bin, 64 KiB; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b. Addresses are offsets in the current full linear 16-bit listing. This is not a proven whole-ROM CFG.

## 1. BP bit 13 is tested but not locally established

At 5CF9h the code tests BP with mask 2000h. If set, it calls F651h with AL=30h and then jumps to D604h. If clear, it falls through to 5D07h, which clears BP bit 12 (mask EFFFh) and continues with the following initialization code.

Important distinction:
- 5C8Ch tests BP bit 12 (mask 1000h) and, if set, jumps directly to 5CF9h.
- 5CF9h tests BP bit 13 (mask 2000h).
- 5D07h clears bit 12, not bit 13.

The full linear listing contains the immediate test of BP mask 2000h at 5CF9h, but no matching immediate OR/AND assignment that sets or clears BP bit 13. The nearby code does not construct that bit. This does not prove the bit can never be supplied through a register load, stack restore, alternate entry, or indirect path; it means the setter is not established by the local static scan.

The earlier POST block at 12D3h–12D4h executes POP BP followed by AND BP,C000h, which clears BP bits 0–13 on that particular path and preserves only bits 14–15. The relationship of that POST path to the later 5C70h entry is not established, so it must not be used to conclude that BP bit 13 is globally always zero.

## 2. The visible 8042 command wrapper preserves DX

The set-bit path at 5CF9h does:
- AL=30h;
- CALL F651h;
- JMP D604h.

F651h is:
- AH=AL;
- AL=60h;
- CALL F622h;
- RET.

F622h uses the common 8042 command/data path:
- CALL F635h;
- if ready, AL=AH and CALL F644h;
- RET.

F635h and F644h save/restore AX around the 8042 wait helper F659h. F659h polls port 64h and uses CX/AL; it does not write DX. No instruction in the visible 5CF9h→F651h→F622h helper chain explicitly assigns DX, DH, or DL.

Therefore the values of DH and DL arriving at 88D3h are inherited from the upstream caller/context. The local path does not derive them from the 8042 status byte or from the command byte 30h. This is a useful negative result: the B3h update condition is not directly computed from the command-byte value in this wrapper.

## 3. 1B5Eh does not initialize BP

At 5C7Dh the code calls 1B5Eh. The bytes at 1B5Eh are a single RET. This call therefore does not establish BP, DH, or DL. The separate routine at 1B5Fh is also a RET; the substantive OEM/option-ROM scan begins at 1B60h and is a different entry.

The later call at 5DBEh targets 1B5Fh and saves/restores BP around it. It does not explain the BP bit 13 tested earlier at 5CF9h.

## 4. Interpretation of the B3h update after this audit

Combining phases 42–44:
- The Setup renderer uses E19Dh bit 1 to select CMOS index B3h versus BAh. That is a UI/index-selection fact, not evidence that the B3h write below is a Setup save.
- The B3h write is reached only on the D604h SYS=0 branch, after the 0100h-count delay, with CR0.PE clear and outside the special DH=4 stack continuation.
- On the ordinary branch, (DL AND 30h)=30h produces AH=02h, which is ORed into CMOS B3h. Existing bits are preserved.
- DH/DL are not initialized in the visible 5CF9h→D604h chain. They are inherited from a not-yet-recovered upstream context.
- BP bit 13 controls whether the 8042 command-byte programming and D604h branch are entered, but its source is not recovered.

## 5. Confirmed versus unresolved

Confirmed:
- BP bit 12 and bit 13 are separate tests at 5C8Ch and 5CF9h respectively.
- The 5CF9h branch only programs command byte 30h and enters D604h when BP bit 13 is set.
- The visible F651h/F622h/F635h/F644h path does not assign DX/DH/DL.
- 1B5Eh and 1B5Fh are RET stubs; neither initializes BP or DX.
- The full linear listing does not expose a direct immediate setter for BP bit 13.

Unresolved:
- The upstream entry and source of BP at 5C70h, including whether BP bit 13 can be supplied by an alternate entry or restored context.
- The upstream source of DH/DL before 5CF9h and the exact caller/register contract at 88D3h.
- The semantic meaning of BP bit 13 and the special DH=4 continuation.
- Whether this 8042/B3h path is executed in the target chipset configuration.

## 6. Phase 44 conclusion

Do not assign a Setup option or hardware feature to CMOS B3h bit 1 yet. The machine code proves the OR condition but not the origin of its input flags. The next useful target is to recover the real entry into the 5C70h region and its register setup, rather than continue interpreting the B3h bit in isolation.
