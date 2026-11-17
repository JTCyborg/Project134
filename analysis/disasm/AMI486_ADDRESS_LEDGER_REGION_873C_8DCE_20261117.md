# AMI486 address ledger — region 873Ch–8DCEh

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Candidate decoder: Capstone x86, 16-bit mode  
Generator: `tools/disasm_ami486_candidate_windows.py`  
Generated candidate listing SHA/blob at this report revision: `dc3b5ceec6c7d049f8b6ac931020429453f5f3b7`.

## 1. Region result

The former candidate-mask gap `873Ch–8DCEh` (1,683 bytes) now has **no uncovered bytes in the candidate code/data union**. The only remaining hole found during the pass, `8B17h–8B2Ch`, was confirmed as the tail of the CMOS feature-query helper at `8B11h` and added through its RET at `8B2Ch`.

This means the interval is represented by bounded code windows, explicit table/data views and stack-return-word ranges. It does **not** mean every byte has one exclusive semantic class: several bytes have confirmed overlapping interpretations, and `8889h–8897h` remains unresolved.

## 2. The 81-entry four-byte configuration array at 873Ch–887Fh

The array is exactly 81 records × 4 bytes = 324 bytes, from `873Ch` through `887Fh`. The four little-endian count words immediately after it are:

| Address | Value | Consumer | Meaning |
|---|---:|---|---|
| `8880h` | 5 | `85F5h` | five-entry prefix at `873Ch` |
| `8882h` | 76 | `85C0h` | 76-entry suffix at `8750h` |
| `8884h` | 0 | `85CBh` | empty optional table slot at `8880h` |
| `8886h` | 81 | `8400h` | all records from `873Ch` |
| `8888h` | E0h | `8378h` | selector threshold for built-in vs optional table |

The arithmetic is exact:
- `873Ch + 5 × 4 = 8750h`
- `8750h + 76 × 4 = 8880h`
- `873Ch + 81 × 4 = 8880h`

### 2.1 Consumer-specific views of each record

The same four bytes have different, independently confirmed meanings depending on the consumer. Do not assign one universal field schema.

**CMOS application at 8400h**
- `+0`: CMOS register number; bit 7 is set before the CMOS helper call.
- `+1`: mask.
- `+2`: desired/default value.
- `+3`: not consumed by this particular CMOS write loop.

The loop loads `CX=[CS:8886h]=81`, starts at `SI=873Ch`, reads the old CMOS byte through `EE94h`, computes the masked merge from record bytes +1/+2, writes through `EE9Dh`, advances SI by four and repeats.

**Key-to-value lookup at 8378h**
- Starts at `BX=873Ch` when `AL <= [CS:8888h]` (E0h).
- For larger keys it switches to the optional table base `[CS:82C0h]`.
- Searches four-byte entries by comparing byte +0 with AL.
- Returns byte +3 in AL, then rotates the result according to the incoming AH bit pattern.

The visible search has no explicit count/end-pointer check; the caller/data contract must provide a matching key or valid table contents.

**Generic masked configuration worker at 85FEh**
- Byte +0 selects the byte index.
- Byte +1 is the mask.
- Byte +2 is selected for input AL=1.
- Byte +3 is selected for input AL=2.
- Input AL=0 takes the existing source byte from DS:E080h+index.
- The destination is DS:E000h+index.

The operation is:
`destination = (destination & ~mask) | (selected_value & mask)`.

This is a DS-relative RAM/configuration-buffer operation, not direct ALi hardware I/O.

### 2.2 Prefix, suffix, optional slot and wrapper flow

- `85F5h` processes the five-entry prefix at `873Ch`.
- `85C0h` processes the 76-entry suffix at `8750h`.
- `85CBh` loads count zero from `8884h` and is a no-op for the stock ROM.
- `85D6h` selects an optional runtime table through `82B0h/82CAh/82C0h`. The stock image has `82B0h=0`, so CX remains zero and this worker returns without processing records. It does **not** fall back to the five-entry prefix; see phase 8 correction.
- The routine beginning at `85B3h` calls `85F5h`, `85CBh`, and `85D6h`, then the `85BFh POP AX` falls through into `85C0h`. It therefore continues through the 76-entry suffix and returns only at `862Fh`.

Consequently, the stock `85B3h` path processes the five-entry prefix, the zero-count slot, the empty optional runtime table, and then the 76-entry suffix: 81 built-in records in total. The same `85C0h` entry is also a direct target of the separate E187h Setup dispatch when E187=2. These are two distinct callers of the same suffix worker.

The earlier phase-6 statement that `85B3h` returns immediately after the optional-table call was incomplete. Phase 6 has been corrected in place.

## 3. Confirmed overlapping 21-record ALi write view at 8750h–87A3h

The 21-record table decoded in phases 33–34 is valid and is **not withdrawn**. It is a separate consumer-specific view of the first 21 records of the 76-record suffix described above.

At `208Dh`, POST computes `(87A4h-8750h)/4 = 21` records. For each record:
- byte 0 is reduced by 30h to obtain the effective ALi register index;
- byte 3 is the value written;
- an effective index of 26h is skipped;
- the other 20 records are written through `8DDCh` to ports 22h/23h.

Thus:
- `873Ch–887Fh`: one 81-record CMOS/configuration array;
- `8750h–887Fh`: its 76-record generic-worker suffix;
- `8750h–87A3h`: the first 21 records of that suffix, also consumed as a separate encoded ALi index/value table by the POST path at 208Dh.

These are overlapping data interpretations, not mutually exclusive table boundaries.

## 4. Further overlapping AUTO Config lookup view at 87A9h–88BBh

The POST AUTO Config consumers use a second table view based at `87A9h`. Its row stride is 20 bytes (`14h`), with 16-bit fields at offsets `+00h`, `+04h`, `+08h`, and `+0Ch`. The selected row is derived from the Setup/CMOS selector and can reach row 13.

The highest field used is at `87B5h + 13 × 14h = 88B9h`, a word ending at `88BAh`. The span of this lookup view is therefore `87A9h–88BBh`.

This view overlaps:
- the 81-entry four-byte array at `87A9h–887Fh`;
- executable code beginning at `8898h`, specifically the final row's fields at `88ADh`, `88B1h`, `88B5h`, and `88B9h`.

The code and table interpretations are both supported by consumers. Do not classify `8898h–88BBh` as code-only or data-only.

## 5. Metadata and unresolved bytes at 8880h–8897h

- `8880h–8887h`: four confirmed count words (5, 76, 0, 81).
- `8888h`: confirmed E0h lookup threshold.
- `8889h–8897h`: no complete consumer/field layout established in this pass. Preserve as unresolved bytes; do not extend the count block to cover them merely because they are adjacent.

The executable entry at `8898h` is independently reached from `ED13h`.

## 6. Executable streams and helper clusters

### 6.1 8898h–88CAh — ALi register-18h feature update

Entry from `ED13h`. The routine:
1. saves general registers and flags;
2. writes ALi register `C5h=03h`;
3. reads ALi register `18h` into BL;
4. reads ALi register `23h` and tests bit 4;
5. if bit 4 is clear, clears bit 0 and sets bit 2 in the saved 18h value; otherwise sets bit 0;
6. writes the resulting value to register `18h`;
7. restores flags/registers and jumps to `ED16h`.

This is a byte-backed relationship between ALi registers 18h and 23h; the hardware meaning of those bits remains unassigned.

### 6.2 88CBh and 88CEh — alternate entries

- `88CBh` is a three-byte near JMP to `AE6Fh`, reached from `AE6Ch`.
- `88CEh` is an independent POST entry reached from `D60Ch`. It begins with a 0100h-count delay, loads SS=CS, and tests the machine-status word/CR0 state. It then performs a CMOS B3h read/modify/write path and a stack-threaded sequence of ALi indexed reads/writes, notably registers C2h and C3h, using `8DCFh`/`8DDCh`.

The arithmetic/flag probe at `8921h` is called through a crafted stack return. It executes XOR/SAHF, divides 5 by 2, LAHF and compares AH with 2 before RET. Its precise diagnostic intent is not established.

Confirmed stack-return words in this stream include:
`88EEh→88F0h`, `890Eh→8910h`, `891Ch→891Eh`, `893Ch→893Eh`, `894Ah→894Ch`, `8952h→8954h`, `8966h→8968h`, `896Eh→8970h`, `8982h→8984h`, `898Eh→8990h`, `899Ch→899Eh`, `89A4h→89A6h`, `89B8h→89BAh`, `89C0h→89C2h`, `89D4h→89D6h`, and `89ECh→89EEh`.

### 6.3 8A04h–8A1Fh — CMOS 8Fh / reset continuation

Entry from `D612h`. The code tests the PE bit using SMSW. On the PE-set path it selects CMOS index 8Fh through port 70h, writes zero through port 71h, and jumps to `8AD5h`. The branch target at `8A1Ah` jumps to `D615h`; the adjacent `8A1Dh` is a separate alternate JMP to `D724h`, not fall-through from the `8A1Ah` jump. The two JCXZ instructions are zero-displacement timing/padding instructions, not table data.

### 6.4 8A20h–8A74h — CMOS B3h-selected ALi profile

Entry from `D652h`. Only AL values 05h, 09h and 0Ah enter the profile path. It reads CMOS B3h, checks the caller's state at `[BP+SI+0CA8h]`, then uses `8CCDh` and selects:
- ten words at `8E62h` when DL bit 2 is set;
- two words at `8E7Ah` when DL bit 2 is clear.

Each word is written through `8DDCh` using a crafted stack return. The continuation returns to `D655h`. The profile arrays themselves are outside this region and are separately classified in the candidate data ranges.

`8A75h` is a three-byte JMP to `D74Ch`.

### 6.5 8A78h–8ACEh — dynamic hook and stack-threaded ALi sequence

Entry from `D774h`. It loads the hook pointer at `CS:82DAh`, sets DI=8A81h and jumps through AX. The stock pointer is `19ABh` (a JMP DI trampoline). The continuation sets DI=8A87h and enters `8CCDh`, then performs stack-threaded ALi register operations through `8D83h`, `8DEDh` and `8DFBh`, including reads/modifications of registers 19h and 18h and calls into the existing 2686h continuation.

The crafted return words are:
- `8A8Eh→8A90h` after the 8D83h sequence;
- `8A9Ah→8A9Ch` after CMOS B3h read;
- `8AA6h→8AA8h` after CMOS write;
- `8AB2h→8AB4h` after ALi indexed write;
- `8ABEh→8AC0h` after ALi indexed read;
- `8ACAh→8ACCh` after ALi indexed write.

The final continuation at `8ACCh` jumps to `D777h`. Separately, `8ACFh` is a trampoline to `F66Ah`.

### 6.6 8AD2h–8AE7h — 8042 reset/wait sequence

`8AD2h` is a near JMP trampoline to `F66Eh`. The alternate entry `8AD5h` (also reached from `F071h)) executes CLI, waits on 8042 status port 64h, writes FEh to port 64h, then halts in a loop. The entry at `8AD6h` begins one byte later in the same CLI sequence. Keep these as overlapping entry streams.

### 6.7 8AE8h–8B2Ch — INT 15h keyboard hook and CMOS feature query

- `8AE8h` is called from the INT 15h dispatcher at `9220h`. It checks AH=4Fh, switches DS to the BDA segment 0040h, tests bits 2/3 at BDA:0017h, and conditionally calls `8B2Dh`.
- `8B09h` preserves AX while executing `MOV AL,FFh; DEC AL`, returning the DEC flags.
- `8B10h` is a one-byte RET stub.
- `8B11h` checks `CS:8281h` bit 6. If clear, it selects CMOS 2Dh through port 70h, reads port 71h, shifts/masks the result and shifts EAX left 16 bits; if the bit is set it bypasses the CMOS read. It returns at `8B2Ch`.

### 6.8 8B2Dh–8CB1h — controller/port configuration dispatch

`8B2Dh` disables interrupts, compares AL against `CS:826Eh` and `CS:825Eh`, checks BDA:0017h bits 0/1 and dispatches to one of four helpers:
- `8BE8h`
- `8B5Eh`
- `8C4Dh`
- `8BA3h`

It restores interrupts and returns.

The four helpers use distinct CS-resident configuration groups:
- `8B5Eh`: fields `8260h–8265h`; optional ALi setup via `8D39h`, optional 8042 transaction via `8CEAh`, then port DX read/modify/write using `(old & mask) | set_bits`; sets BDA:0016h bit 5.
- `8BA3h`: fields `8250h–8255h`; optional ALi setup via `8D09h`, optional 8042 transaction, port DX read/modify/write; clears BDA:0016h bit 5.
- `8BE8h`: fields `8268h–826Dh`; conditionally invokes the CR0 helper and `8D83h`, optional 8042 transaction, port DX read/modify/write; clears BDA:0016h bit 4.
- `8C4Dh`: fields `8258h–825Dh`; conditionally invokes the alternate CR0 helper and `8D56h`, optional 8042 transaction, port DX read/modify/write; sets BDA:0016h bit 4.

The exact external device names associated with these port groups remain unresolved; retain the literal ports, masks and BDA bit effects rather than assigning guessed device labels.

### 6.9 8CB2h/8CCDh — CR0 cache-state helpers

Both are DI-returning continuations:
- `8CB2h` checks PE=0 and AH=0, clears EAX bits 29/30 with mask `9FFFFFFFh`, writes CR0, clears AX and jumps DI.
- `8CCDh` checks the same conditions, sets EAX bits 29/30 with `60000000h`, writes CR0, executes WBINVD, clears AX and jumps DI.

They are used as paired cache-state transitions. Do not infer a broader CPU mode transition from these helpers alone.

### 6.10 8CEAh–8D08h — 8042 command/data helper

Input AL is saved in AH. The routine waits for input-buffer-full bit 1 at port 64h to clear, writes the command to port 64h, waits for output-buffer-full bit 0 to set, reads port 60h and returns the byte in AL. CX=0 initializes the LOOP-family waits as long bounded polling loops. Timeout exits return without the final data read.

### 6.11 8D09h–8DCEh — ALi indexed-register setup callbacks

- `8D09h`: writes C5h=03h; reads/modifies register 18h (sets then clears bit 2 in the observed sequence); reads/modifies register 23h (sets bit 1); writes 55h=03h; returns CX=0.
- `8D39h`: writes C5h=03h; clears bit 1 in register 23h; writes 55h=03h; returns CX=0.
- `8D56h`: writes C5h=03h; tests register 18h bit 1; when clear, uses 2686h/2629h continuations and sets bit 1; returns CX=FFFFh.
- `8D83h`: writes C5h=03h; uses indirect read/write trampolines to set register 19h bits 0/1, invoke 2686h, clear register 19h bits 0/1, clear register 18h bit 1, then returns CX=FFFFh.

The register bit operations are proven; their board-level meaning is not.

### 6.12 Shared indexed I/O helpers

- `8DCFh`: OUT 22h,AL; IN AL,23h; RET.
- `8DDCh`: OUT 22h,AL; XCHG AL,AH; OUT 23h,AL; XCHG AL,AH; RET.
- `8DEDh`: indexed read, then JMP DI.
- `8DFBh`: indexed write, then JMP DI.

The zero-displacement JCXZ instructions are byte-backed timing/padding between I/O operations. These helpers explain the stack-return and DI-return patterns throughout the region.

## 7. Incoming references and unresolved provenance

The full linear listing shows direct near references into this region from:
- `ED13h -> 8898h`
- `AE6Ch -> 88CBh`
- `D60Ch -> 88CEh`
- `D612h -> 8A04h`
- `D652h -> 8A20h`
- `D749h -> 8A75h`
- `D774h -> 8A78h`
- `90F3h -> 8ACFh`
- `528Eh/9191h/91D9h/920Eh -> 8AD2h`
- `F071h -> 8AD5h`
- `527Ah/5480h -> 8AD6h`
- `9220h -> 8AE8h`
- `D029h -> 8B09h`
- `E995h -> 8B10h`
- `F84Dh -> 8B11h`
- `B026h -> 8B2Dh`
- `1E2Ch/9484h -> 8B5Eh`
- `1E27h/9474h -> 8BA3h`
- `1F26h/271Fh/2859h -> 8CB2h`
- `1EF7h/1F37h -> 8CCDh`
- `27D7h/28D8h -> 8D83h`

Some entries are intentionally overlapping (notably 88CBh/88CEh and 8AD2h/8AD5h/8AD6h). The source-side instruction boundaries of every incoming xref have not all been re-audited in this pass; treat the list as the current cross-reference candidate set, not a proof of global reachability.

Unresolved:
- runtime producer and contents of `82C0h/82C2h/82CAh`;
- producer/meaning of `CS:8281h` bit 6;
- exact semantics of the arithmetic/flag probe at `8921h`;
- hardware/device labels for the port groups at `8250h–826Dh`;
- semantic names for ALi register bits touched by `8D09h–8D83h`;
- bytes `8889h–8897h` and their possible secondary consumers;
- full reachability/entry proof for each independent seed.

## 8. Candidate-mask status after this expansion

Latest generated candidate mask:
- 678 code windows;
- 205 data ranges;
- 34,292 unique code-window bytes;
- 16,419 unique data-range bytes;
- 213 overlap bytes;
- 50,498-byte union (**77.05%** of the 64-KiB image);
- 70 uncovered intervals;
- 223 pages touched, 147 fully covered.

The selected interval `873Ch–8DCEh` has zero uncovered bytes in this mask. This is a bounded inspection mask, not a whole-ROM semantic completion percentage.

The next largest uncovered interval in the current mask is `2436h–29F5h` (1,472 bytes). Other large gaps include `FA53h–FFFFh`, `5A4Ch–5FE3h`, and `1365h–188Dh`.
