# AMI486 semantic map — phase 43 (2026-11-16)

## Scope and ROM basis

Followed the sole direct entry to D604h, the 8042 status test at D606h–D612h, and the continuation at 88CEh–893Ch. This phase adds the caller context missing in phase 42.

ROM: ami486.bin, 64 KiB; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b. Addresses are offsets in the existing linear 16-bit decode. Embedded continuation bytes and indirect transfers mean the linear decode must not be treated as a complete CFG.

## 1. D604h is reached from a specific 8042 command-byte path

The only direct transfer into D604h in the listing is the near JMP at 5D04h. The preceding code at 5CF9h–5D04h:

- tests BP bit 13 (mask 2000h);
- when set, loads AL=30h;
- calls F651h;
- jumps to D604h.

F651h is not a direct port write of 30h. It moves AL into AH, sets AL=60h, and calls F622h. F622h is the shared 8042 command/data transfer helper (its exact wait/output details are covered by the existing 8042 helper analysis). This sequence therefore requests command 60h to the 8042 and supplies data 30h: it programs the controller command byte to 30h, subject to helper success.

The branch is conditional on BP bit 13. In the displayed local code, 5D07h clears BP bit 12 (mask EFFFh), not bit 13; do not conflate these two flags. The origin and full lifetime of BP bit 13 are not yet recovered.

## 2. D604h tests the 8042 system flag, not input-buffer-busy

At D604h the code executes CLI and CLD, reads port 64h, and tests bit 2:

- if bit 2 is clear, it jumps to 88CEh;
- if bit 2 is set, it jumps to D612h, which transfers to 8A04h.

On the standard 8042 status-byte definition, bit 2 is the system flag (SYS), while bit 1 is input-buffer-full (IBF) and bit 0 is output-buffer-full (OBF). Thus the D606h test is not a test for IBF/busy. The ROM's branch is explicitly on SYS=0 versus SYS=1.

The code at 5CF9h–5D04h therefore forms a controller-command-byte setup followed by a SYS-status-dependent branch. It is reasonable to describe this as an 8042 initialization/check path; assigning a more specific chipset or keyboard feature requires runtime or additional call-chain evidence.

## 3. Conditions for reaching the CMOS B3h update

Only the SYS=0 branch reaches 88CEh. It executes a 0100h-iteration CX delay loop, then falls through to 88D3h.

At 88D3h:

1. SS is set to CS.
2. SMSW AX is executed.
3. If CR0.PE (AL bit 0) is set, execution branches to 891Eh and bypasses the B3h read/modify/write path.
4. If PE=0, the high byte AH returned by SMSW is tested. A nonzero AH takes the 8904h continuation; zero proceeds to compare DH with 4.
5. If DH=4 and SMSW AH=0, the special continuation at 88E8h–88F5h is selected.
6. Otherwise, the DL mask path at 88FAh checks (DL AND 30h)==30h.

On that ordinary DL path, AH is set to 02h if both DL bits 4 and 5 are set, otherwise AH=00h. The continuation at 8906h reads CMOS B3h via EE94h, ORs AH into the returned byte at 8912h, and writes B3h via EE9Dh at 8914h. Consequently, this branch can set B3h bit 1 but cannot clear any B3h bits.

The special DH=4 path uses SP=88EEh and enters the 8921h continuation, bypassing the ordinary local DL mask. The bytes at 88EEh–88F5h are continuation data/code selected by the manually arranged stack; they must not be read as ordinary linear instructions. This phase does not assign the special path a CMOS meaning.

## 4. What is and is not established

Confirmed:
- D604h has a single direct entry in the listing, from 5D04h.
- The caller sets the 8042 command byte using command 60h / data 30h before entering D604h, conditional on BP bit 13.
- D606h tests 8042 status bit 2 (SYS), not IBF bit 1.
- SYS=0 reaches the delay loop and then 88D3h; SYS=1 branches to 8A04h instead.
- CR0.PE=1 bypasses the B3h RMW path.
- On the ordinary real-mode path, DL bits 4 and 5 together cause B3h bit 1 to be ORed in.

Unresolved:
- The origin/meaning of BP bit 13 and the broader routine that reaches 5CF9h.
- The runtime provenance of DH and DL at 88D3h.
- The special DH=4 continuation at 88E8h–8921h.
- Whether the command-byte value 30h has a board-specific interpretation beyond the standard 8042 command-byte bit assignments.
- The exact user-visible Setup label remains unknown; the Setup renderer evidence from phase 42 is independent and does not make this path a Setup save handler.

## 5. Correction / refinement to phase 42

Phase 42 correctly separated the Setup renderer from the 88D3h continuation. This phase narrows the latter: it is downstream of a conditional 8042 command-byte programming path and an 8042 SYS-bit test. It is not justified to call the port-64 test a generic busy check, or to claim the B3h update is a Setup Save operation.
