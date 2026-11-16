# AMI486 semantic map — phase 56 (2026-11-16)

## Scope

Audit additional BP producers around the candidate POST paths and distinguish the 11xx early-POST status accumulator from the later 5Cxx memory-test state. Recheck whether the indirect dispatch tables in the 87xx region provide an overlooked DAxx entry.

## 1. Early POST BP flags at 113B–11BC are temporary

The sequence beginning at 1100h is a keyboard-controller / interrupt-controller initialization and hardware status collection path:

- 113Bh: `OR BP,0200h` on the first result branch.
- 1141h: `OR BP,0400h` on the alternate result branch.
- 117Fh: `OR BP,0100h` when status bit 10h is clear.
- 11A1h and 11BCh: `OR BP,0800h` when the two compared BIOS/CMOS values disagree.

At 11DFh the code saves BP, then conditionally clears status bits:
- 11E5h clears bits 8–10 with mask F8FFh.
- 11EEh clears bits 6–7 with mask FF3Fh.
- 11FDh clears sign bit 15 with mask 7FFFh.

The saved BP is restored at 12D3h, then 12D4h applies `AND BP,C000h`. This keeps only BP.15 and BP.14 and clears bits 0–13. Therefore the flags collected at 113Bh–11BCh do not explain BP.13 at a later point that is downstream of this restore.

This is a path-local conclusion: it does not establish that the 5Cxx POST block executes after this 12D3h restore. The actual runtime ordering between the early POST sequence and the DAxx/5Cxx continuation remains to be proven.

## 2. The separate memory-probe error bit is BP.14

At 27D0h the memory probe executes `OR BP,4000h` before entering the failure/report path at 8D83h. This sets bit 14, not bit 13. The successful branch at 27DEh does not set BP.14.

This is consistent with the 12D4h mask preserving BP.14 while discarding bits 0–13, but no direct control-flow edge has yet been proven between this probe and the 5Cxx memory-test continuation.

## 3. Later 5Cxx flag producers

The verified 5Cxx path still shows:
- 5C58h tests sign bit 15 without changing BP.
- 5C8Ch tests bit 12.
- 5CC6h and 5CF0h OR BP with zero; no bit is set.
- 5CF9h tests bit 13.
- 5D07h clears bit 12 only.
- 5DBDh PUSH BP / 5DC1h POP BP preserves BP around the RET stub at 1B5Fh.
- 5DF7h tests sign bit 15.
- 5ECCh sets bit 7.
- 5F7Dh sets bit 6.

No instruction in the verified 5C04h–5F7Dh path writes BP.13.

## 4. 87xx indirect-dispatch audit

The linear decode shows several indirect transfers in the 87xx/88xx range, including:
- 8785h: `JMP word ptr [BX+DI]`
- 8799h: `JMP word ptr [DI-3Bh]`
- 881Dh: `JMP word ptr [BP+66h]`
- 8831h: `JMP word ptr [SI]`

However, the bytes around 873Ch–87A3h overlap the BIOS's structured option/configuration data (the same region previously identified as default/configuration records). Treating every linear instruction decode in this region as executable code would produce false control-flow edges. The apparent 87xx indirect jumps are therefore not accepted as DAxx callers without a runtime entry and valid table-base provenance.

The actual executable indirect dispatches already established elsewhere (e.g. D6A2h's selector table and the 8A7Fh/19ABh trampoline) do not presently provide a proven edge to DA61h or DA9Fh.

## 5. Updated conclusion on BP.13

The evidence now separates three classes of BP state:
1. Early POST status flags 8–11, which are explicitly discarded by the later `POP BP; AND BP,C000h` sequence at 12D3h–12D4h, if that path precedes the later test.
2. Memory-probe error bit 14, set at 27D0h only on its failure path.
3. 5Cxx runtime state, where bit 13 is tested at 5CF9h but is not produced locally.

No direct immediate BP write setting 2000h has been identified in the verified code paths. A POP BP or other stack restoration from an earlier caller remains a plausible mechanism, but the source frame and runtime order are not yet proven.

## 6. Confirmed vs unresolved

### Confirmed
- 113Bh/1141h/117Fh/11A1h/11BCh collect BP bits 9, 10, 8 and 11.
- 12D3h restores the saved BP and 12D4h retains only bits 14–15.
- 27D0h sets BP.14, not BP.13, and only on the memory-probe failure branch.
- The 5Cxx local path does not set BP.13.
- 87xx contains structured configuration/default data; its linear decode cannot be treated as executable CFG without additional evidence.

### Unresolved
- Whether 12D3h precedes or follows the runtime entry to the DAxx/5Cxx sequence.
- Which caller or stack frame supplies BP at the start of the DAxx path.
- Whether a valid alternate entry into DAxx is mediated by an indirect transfer not represented as a direct near CALL/JMP.
- The original producer of BP.13.
