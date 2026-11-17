# AMI486 address ledger — Advanced CMOS CPU/cache profile data and CMOS 8Eh selector (81EEh–8377h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Scope and corrected boundaries

This pass corrects the candidate-generator classification. The executable stream begins at 8300h, not 8328h. The bytes at 8328h and 832Eh are inside instructions and must not be used as independent seeds.

| Range | Classification | Notes |
|---|---|---|
| 81EEh–8325h | Data | Advanced CMOS/CPU-profile configuration block |
| 8300h–8305h | Code | BX-preserving wrapper |
| 8306h–8325h | Code | CPU-profile index selector / alternate transfer into shared walker |
| 8326h–8377h | Code | Profile-record walker and CMOS 8Eh update |
| 8378h onward | Separate code entry | Existing independently seeded continuation |

The former data range ended at 8327h inclusive and incorrectly swallowed the first two bytes of the executable instruction at 8326h (2E 8B). The corrected data range is half-open 81EEh–8326h. The old seeds 8328h and 832Eh were invalid: 8328h is the ModR/M byte of the instruction beginning at 8326h, and 832Eh is the relative displacement byte of the conditional branch beginning at 832Dh.

## 2. Advanced CMOS/profile data block — 81EEh–8325h

The block is not a single executable stream. It contains zero-filled/reserved fields, board configuration values, I/O base-address words and pointer/offset data associated with the CPU/cache profile records.

Confirmed little-endian I/O base-address words include:

| ROM offset | Stored bytes | Value |
|---:|---:|---:|
| 8240h | F8 03 | 03F8h |
| 8242h | F8 02 | 02F8h |
| 8244h | E8 03 | 03E8h |
| 8246h | E8 02 | 02E8h |
| 8248h | BC 03 | 03BCh |
| 824Ah | 78 03 | 0378h |
| 824Ch | 78 02 | 0278h |

The byte pair at 823Eh–823Fh is retained as part of the surrounding configuration record; it is not folded into the aligned word list above.

The word table at 82C6h–82EBh contains offsets into the ROM's CPU/cache profile data area around 19A2h–19AFh. Its first word is 19A3h, which is loaded by the 8326h walker through CS:[82C6h]. Other entries include 19A2h, 19A5h, 19A7h, 19A9h, 19ABh, 19ADh and 19AEh, interspersed with zero entries. The precise meaning of every profile record and the semantics of each field remain unresolved.

Other pointer-like values around 828Eh–82C5h reference ROM data in the 87xx/88xx and CAxx regions. They are retained as data; no linear instruction interpretation is assigned.

## 3. BX-preserving wrapper — 8300h–8305h

8300  53          push bx
8301  E8 02 00    call 8306h
8304  5B          pop bx
8305  C3          ret

This wrapper preserves the caller's BX while invoking the profile selector at 8306h.

## 4. CPU-profile selector — 8306h–8325h

The routine tests the incoming AL value:
- AL=00h branches to the CMOS 8Eh update continuation at 834Fh.
- For nonzero AL, it clears AH, constructs the comparison value 0055h (B55Dh - B508h), and compares AX against it.
- If AX is below 0055h, it transfers to 832Fh with BX preloaded to B7D0h. This is an alternate entry into the shared record-walking body; it deliberately skips the 8326h setup that loads BX from CS:[82C6h].
- Otherwise it subtracts 0055h from AX and falls through directly into the 8326h profile-record walker. There is no RET at 8325h; the 8326h instruction is the next sequential instruction.

The 831Bh short conditional branch targets 832Fh. That target is an instruction boundary inside the shared walker, not an independent function prologue.

## 5. Profile-record walker and CMOS 8Eh update — 8326h–8377h

The entry/fall-through at 8326h loads BX from the word at CS:82C6h (19A3h in this ROM), tests AL, and either skips directly to the CMOS update at 834Fh or iterates the profile records. It is reached both sequentially after the 8324h SUB AX,BX and independently through other entry paths.

The loop uses a 20h-byte record stride. It reads record byte +1Eh into AH, adds record byte +1Fh to BL with carry into BH, advances BX by 20h, and tests bit 7 of the saved record byte. When that bit is set, it advances by words until the word at CS:[BX-2] is zero. It then decrements AL and repeats while AL is nonzero.

The record fields at +1Ch and +1Dh are subsequently loaded for the CMOS update. The code selects CMOS register 8Eh through port 70h, applies short I/O delays, reads the current value through port 71h, and tests bits C0h of the current value. Depending on those bits, it sets or clears bit 7 in the selected record value before continuing into the shared continuation beyond 8377h.

This establishes that the routine uses profile-record data to update CMOS register 8Eh. It does not establish symbolic names for the C0h/80h bits or the board-specific meaning of each profile entry.

## 6. Entry and boundary ledger

| Address | Role |
|---:|---|
| 8300h | Wrapper preserving BX |
| 8306h | CPU-profile selector |
| 8326h | Profile-record walker entry and fall-through from 8324h; loads BX from CS:82C6h |
| 832Fh | Alternate walker entry reached with BX=B7D0h from 831Bh |
| 834Fh | CMOS register 8Eh selection/read continuation |
| 8351h | CMOS read continuation reached when AL=0 at the 8326h entry |
| 8374h | Alternate CMOS-bit handling branch inside the same routine |
| 8378h | Next separately seeded code entry; boundary of this ledger interval |

## 7. Generator correction and verification status

The candidate generator was corrected to:
- end the data range at 8326h (exclusive);
- remove invalid seeds 8328h and 832Eh;
- seed 8300h with a 06h-byte wrapper window;
- seed 8306h with a 20h-byte selector window;
- seed 8326h with a 52h-byte walker window, ending immediately before 8378h.

The generator boundary correction is commit a263b7baf68c45be27e3d1aefde63efd0fdc7251. The regenerated manifest commit is 81616282fb759ee64603a84a7fc43f1c5170961c and reports 858 windows, 242 data ranges, 62,431 covered bytes (95.26%), and 60 uncovered intervals. The largest remaining uncovered interval is 84CAh–85B2h (233 bytes).

No post-change GitHub Actions manifest has yet been observed for this commit. Therefore this report does not claim a new global coverage percentage or CI pass. The next step is to run the candidate generator/CI, inspect the updated uncovered-interval manifest, and take the next largest real gap.

## 8. Remaining uncertainties

- Exact meanings of CMOS 8Eh bits C0h and 80h.
- Complete field semantics of the 20h-byte CPU/cache profile records.
- The meaning of the alternate B7D0h profile base and how it relates to the pointer table at 82C6h.
- The downstream continuation reached after the CMOS 8Eh read/update path.
