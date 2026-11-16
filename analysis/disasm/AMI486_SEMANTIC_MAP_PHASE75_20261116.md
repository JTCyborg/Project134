# AMI486 semantic map — phase 75 (2026-11-16)

## 1. Newly identified direct CMOS scan loops

The byte sequences at 17F0h and 1810h are instruction-aligned CMOS read loops, not random OUT/IN byte patterns.

### Loop A: CMOS indices 90h through ADh

```asm
17F0  XOR BX,BX
17F2  MOV AH,0
17F4  MOV CL,90h
17F6  MOV AL,CL
17F8  OUT 70h,AL
17FA  JCXZ 17FCh
17FC  JCXZ 17FEh
17FE  IN AL,71h
1800  JCXZ 1802h
1802  ADD BX,AX
1804  INC CL
1806  CMP CL,ADh
1809  JBE 17F6h
180B  JMP DI
```

This reads CMOS indices 90h..ADh inclusive and accumulates each byte into BX. The two JCXZ +0 instructions are timing gaps. The final `JMP DI` is an indirect continuation, not a normal RET.

### Loop B: CMOS indices B4h through BEh, with a configured upper bound

```asm
1810  XOR BX,BX
1812  MOV AH,0
1814  MOV CX,00B4h
1817  MOV AL,CL
1819  OUT 70h,AL
181B  JCXZ 181Dh
181D  JCXZ 181Fh
181F  IN AL,71h
1821  JCXZ 1823h
1823  ADD BX,AX
1825  INC CX
1827  CMP CX,00BEh
182B  JNZ 182Fh
182Dh  INC CX
182Eh  INC CX
1830  CS: CMP CX,[82B3h]
1835  JBE 1817h
1837  JMP DI
```

The loop starts at B4h, reads CMOS bytes, and sums them into BX. When CX reaches BEh it skips two indices before comparing CX with the CS-qualified word at 82B3h; otherwise it compares the incremented index directly. It terminates once CX exceeds the configured bound, then dispatches through DI. The exact meaning and initialization of CS:[82B3h] still need tracing.

These loops show the BIOS performs checksumming/aggregation over CMOS/NVRAM ranges beyond the single B6h flag. They do not, by themselves, establish that B6h is written.

## 2. EE9Dh write-helper caller scan: current status

A raw relative-CALL scan found candidate call offsets:
11C4h, 11DCh, 146Bh, 14F6h, 159Bh, 183Fh, 1846h, 1853h, 1C1Ch, 1C25h, 1C30h, 1C3Bh, 50A1h, 5255h, 525Ch, 5268h, 545Ch, 5475h, 54C9h, 5D75h, 5D91h, 5D99h, 5F8Ah, 5FE0h, 85A9h, and EEC3h.

This is a candidate list, not yet a validated caller list: the ROM contains overlapping code, embedded tables, and alternative entry points, so byte-pattern CALL matches must be checked against reachable instruction boundaries before attributing semantics.

Several offsets in the 17F0h/1810h loops are direct CMOS I/O and not EE9Dh calls. The CMOS write primitive EE9Dh remains:
```asm
EE9D  OUT 70h,AL
EE9F  XCHG AH,AL
EEA1  JCXZ EEA3h
EEA3  JCXZ EEA5h
EEA5  OUT 71h,AL
EEA7  XCHG AH,AL
EEA9  RET
```

No confirmed write of CMOS index B6h has yet been found. The immediate AX=B6B6h at 29EDh remains the only confirmed B6h selector in the image, and it is a read through EE94h.

## 3. Other useful direct I/O sites

- 13F8h is a direct OUT 70h,AL site preceded by a bounded loop; requires instruction-boundary and caller reconstruction.
- 14D0h–1508h contains direct port 80h/CMOS helper activity and checks bit 2 of CMOS byte 10h, then updates bit 3 in that byte through a read/modify/write path. This is distinct from CMOS B6h.0.
- 5E10h–5E30h performs direct port 80h activity and selects CMOS index 8Dh before calling a helper; caller context remains to be traced.
- 834Fh–8372h reads CMOS and conditionally writes back a modified value (OR 80h or AND 7Fh), but the exact index is taken from a preceding register/structure field and needs caller analysis.

## 4. Conclusions / next targets

- The BIOS has explicit CMOS range-summing loops at 17F0h and 1810h; the second loop's upper bound is CS:[82B3h].
- This gives a new path to determine whether B6h belongs to a checksummed NVRAM region, but it does not prove the flag is writable.
- Continue from the validated instruction boundaries around 14D0h–1508h, 834Fh–8372h and the 13F8h port-70 loop.
- Continue the separate BP.13 provenance and DA5Eh/DA61h dynamic-entry analysis.
