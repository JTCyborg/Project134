# AMI486 semantic map — phase 47 (2026-11-16)

## Scope and source

ROM ami486.bin (64 KiB), SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b. This phase follows the newly confirmed D8/D9 entries and reconstructs the 88E8h stack continuation. The listing remains a linear decode; embedded continuations must be interpreted from their actual stack setup.

## 1. 88E8h–8930h: exact stack continuation

At 88E2h the code tests DH against 4. If equal, it executes:
- 88E8h: MOV SP,88EEh
- 88EBh: JMP 8921h
- 8921h–8930h: arithmetic/flags helper ending in RET at 8930h.

The RET at 8930h pops the word stored at 88EEh. ROM bytes 88EEh–88EFh are F0 88, so the popped return IP is 88F0h. This is not a return to 88EFh and does not execute the leading F0h prefix as an instruction. The continuation therefore resumes at 88F0h:
- 88F0h: JNE 88FAh
- if not taken: 88F2h MOV DI,88F8h; 88F5h JMP 8931h
- 88FAh: ordinary path masks DL with 30h and chooses AH=02h only when the masked value is 30h; otherwise AH=00h.

Thus the DH=4 branch is a deliberate stack-built branch into a short continuation that chooses between the indexed ALi read at 8931h and the ordinary CMOS B3h read/modify/write at 8906h–8919h. The branch condition at 88F0h is the result of the helper at 8921h–8930h, not a direct test of DH or DL.

## 2. What the 8921h helper computes

8921h executes XOR AX,AX; SAHF; MOV AX,5; MOV BX,2; DIV BL; LAHF; CMP AH,2; RET.

DIV BL computes 5 / 2, leaving quotient AL=2 and remainder AH=1. The arithmetic flags after DIV are architecturally undefined, and LAHF copies the current status flags into AH. Therefore the subsequent CMP AH,2 is not a portable or semantically stable boolean calculation: it compares a value derived from undefined DIV flags. On a specific CPU/emulator the result may be deterministic, but the ROM alone does not define the branch outcome. The crafted return address 88F0h is certain; whether JNE at 88F0h is taken depends on the implementation's post-DIV flags.

Correction: do not describe the DH=4 path as reliably selecting either 8931h or 8906h based solely on the instruction sequence. Its intended outcome likely depends on legacy CPU flag behavior, but that intent is not proven.

## 3. 8400h / 84C8h entry remains unresolved

8400h is immediately after RET at 83FFh, so ordinary fall-through from the preceding function is impossible. Static direct-transfer search finds no direct CALL/JMP to 8400h. The visible 84C8h transfer is internal: 8491h jumps there after the SI scan reaches CS:82C2h. The path from 8400h checks CS:8280 bit6; when set it bypasses D90Dh and executes CMOS operations, including an update at 841Ah (AND BP,FFC7h), which clears BP bits 3–5.

84C8h is reached from the 8485h–84C6h scan loop; it is not an independent external caller. The routine's external entry at 8400h therefore remains an indirect/function-table/alternate-entry candidate. No exact pointer/reference to 8400h or 88EEh was found in the linear instruction listing.

## 4. BP bit-13 status

Neither the 8400h branch nor the 86D8h→D8EAh branch sets BP bit13. 8400h's alternate branch clears bits 3–5 via AND BP,FFC7h. The D8EAh path ORs bits 3,4,5 only. The 5CF9h TEST BP,2000h source remains unidentified.

5C50h/5C60h paths use stack-crafted continuations at 5C56h and 5C66h; 5C58h tests BP sign, and 5C8Ch tests BP bit12. The stack return at 5C56h begins POP AX / POP SP, so linear decoding after that point cannot be trusted as ordinary sequential code. Do not infer that the visible 5C70h MOV ES,AX is reached from 5C60h without reconstructing the continuation words.

## 5. Conclusions

- The DH=4 special case sets SP=88EEh and returns from 8930h to 88F0h exactly.
- The continuation's conditional outcome is based on undefined flags after DIV BL; emulator/CPU-specific behavior must be measured before asserting the chosen branch.
- 8400h has no direct CALL/JMP reference in the full linear listing; 84C8h is only the internal completion branch of that routine.
- BP bit13 provenance remains unresolved. The examined D8/D9 and 8400h code does not supply it.

Next: identify the indirect dispatch/table entry into 8400h, and reconstruct the 5C50h/5C60h stack words. Keep BP bit13 marked unknown until an actual write or stack restoration into BP is traced.