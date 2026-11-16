# AMI486 semantic map — phase 78 (2026-11-16)

## 1. The CMOS sum loops have verified write-back continuations

The indirect `JMP DI` at the end of the first sum loop (1834h) and the second sum loop (1835h) is now resolved by matching the caller setup with the actual instruction boundaries.

### First range: 90h..ADh, stored at AEh/AFh

The aligned continuation setup is:

```asm
1834  JMP DI
1836  MOV DI,183Bh
1839  JMP SHORT 17F2h
```

The first sum loop at 17F2h accumulates CMOS indices 90h through ADh into BX. It returns through DI to 183Bh, where the continuation is:

```asm
183B  MOV AL,AEh
183D  MOV AH,BH
183F  CALL EE9Dh
1842  MOV AL,AFh
1844  MOV AH,BL
1846  CALL EE9Dh
1849  RET
```

EE9Dh is the CMOS write primitive: it selects the index using AL at port 70h, transfers AH to port 71h, and restores AX. Therefore the accumulated 16-bit BX value is stored with BH at CMOS AEh and BL at CMOS AFh.

### Second range: B4h..BDh and C0h..E0h, stored at BEh/BFh

The second continuation setup is:

```asm
184A  MOV DI,184Fh
184D  JMP SHORT 1810h
```

The loop at 1810h accumulates the configured CMOS range into BX, then dispatches to 184Fh:

```asm
184F  MOV AL,BEh
1851  MOV AH,BH
1853  CALL EE9Dh
1856  MOV AL,BFh
1858  JMP SHORT 1844h
```

The jump lands on the already decoded `MOV AH,BL; CALL EE9Dh; RET` sequence at 1844h. Thus BH is stored at CMOS BEh and BL at CMOS BFh.

## 2. What this establishes

The two loops are not merely diagnostic sums returned to an unknown caller. Their DI-selected continuations explicitly persist each 16-bit sum in CMOS:

- CMOS AEh:AFh receives the sum of CMOS 90h..ADh.
- CMOS BEh:BFh receives the sum of CMOS B4h..BDh plus C0h..E0h.

This is direct evidence of two CMOS/NVRAM checksum fields. The code shown computes and writes the sums; it does not, by itself, prove a later verification/compare policy or identify the higher-level configuration structure.

## 3. Corrections to phase 77

The previous phase 77 report had instruction offsets shifted by one byte in the dispatcher description. The checked-in ROM bytes give the correct aligned sequence:

- 1834h: `JMP DI`
- 1836h: `MOV DI,183Bh`
- 1839h: `JMP SHORT 17F2h`

The alternate jump target is 17F2h, the aligned `XOR BX,BX` entry, not 17F3h. The second setup is 184Ah..184Eh and jumps to 1810h, the aligned `XOR BX,BX` entry. The checksum write continuations start at 183Bh and 184Fh respectively.

The three write-helper CALLs are at 183Fh, 1846h and 1853h; all resolve to EE9Dh. The prior phase 77 note that they target EE9Eh is incorrect and is withdrawn. They execute the full write helper, including CMOS index selection at port 70h.

## 4. Remaining work

- Trace the callers/entry conditions for the two checksum-update sequences and determine when these CMOS fields are refreshed.
- Search for reads/comparisons of CMOS AEh:AFh and BEh:BFh to determine whether the BIOS validates the stored sums elsewhere.
- Continue the separate BP.13 producer search and dynamic-entry analysis for DA5Eh/DA61h.
