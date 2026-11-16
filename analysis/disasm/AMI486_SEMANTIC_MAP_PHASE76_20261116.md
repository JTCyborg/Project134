# AMI486 semantic map — phase 76 (2026-11-16)

## 1. Resolve the upper bound at CS:82B3h

The bytes at ROM offset 82B3h are:

```
82B0: 00 88 88 E0 00 00 A3 19
```

Thus the word at CS:82B3h is 00E0h. In the loop at 1810h, the relevant instruction is a CS-qualified memory compare:

```asm
1825  INC CX
1827  CMP CX,00BEh
182B  JNZ 182Fh
182D  INC CX
182E  INC CX
1830  CS: CMP CX,[82B3h]   ; [CS:82B3] = 00E0h
1835  JBE 1817h
1837  JMP DI
```

This makes the iteration range precise:
- B4h through BDh are read normally.
- BEh and BFh are skipped.
- C0h through E0h are read.
- The loop exits after CX advances beyond E0h.

Every read byte is added to BX. This is a checksum/sum accumulator over a deliberately discontinuous CMOS/NVRAM range. The final sum is returned in BX to the continuation selected in DI. Whether the caller compares this sum to a stored checksum is the next question; the loop alone does not establish that.

## 2. Confirmed first CMOS scan range

The 17F0h loop is also exact:
- starts at CMOS index 90h,
- reads through ADh inclusive,
- accumulates each byte in BX,
- then jumps through DI.

It does not write CMOS. The OUT instruction targets port 70h (index select), and IN reads port 71h (data).

## 3. Reclassification of 14D0h–1518h

The previous phase 75 note that this entire region was a CMOS 10h read/modify/write path was too strong. Re-reading aligned instructions shows several POST-code writes to port 80h mixed with CMOS accesses:

```asm
14D0  MOV AX,[DF24h]
14D3  JCXZ 14D5h
14D5  JCXZ 14D7h
14D7  OUT 80h,AL
14D9  MOV AL,9Dh
14DB  OUT 80h,AL
14DD  CLI
14DE  MOV AL,94h
14E0  CALL EE94h       ; read CMOS index 94h
14E3  MOV AH,AL
14E5  XOR AL,[0010h]
14E8  TEST AL,02h
...
14F0  XOR AH,02h       ; candidate update to value held in AH
14F2  MOV AL,94h
14F4  CALL EE94h       ; this is another READ, not a CMOS write
```

The apparent second helper call is EE94h (read), not EE9Dh (write). Consequently, the earlier claim that this code writes CMOS register 10h is withdrawn. The exact update path must be decoded further; the 94h register read and comparison against memory byte 0010h are established, but no CMOS write is proven by this snippet.

Port 80h writes  A1h and 9Dh are POST/debug codes, not CMOS indices. This distinction matters because the port number is different: CMOS index is selected at 70h, while these status bytes are sent to 80h.

## 4. BP.13 checkpoint

The aligned sequence at 5CF8h is:

```asm
5CF8  TEST BP,2000h
5CFD  JZ ...
```

This is a read/test of BP bit 13 only. The nearby 5D08h instruction is `AND BP,EFFFh`, which clears bit 12, not bit 13. No BP.13 producer is established by this block. Do not infer that the CMOS scan or the 29BBh RAM test sets BP.13; the latter was proven to set BP.14 on failure only.

## 5. Next work

- Trace the two checksum sums (90h..ADh and B4h..BDh plus C0h..E0h) from their DI-selected continuations and identify any comparison/stored checksum.
- Correctly classify the 14D0h sequence and continue around 14F0h–1528h to determine whether it changes CMOS or only RAM shadow/configuration state.
- Validate actual EE9Dh write-helper callers from instruction boundaries rather than raw byte matches.
- Continue the independent BP.13 producer search and DA5Eh/DA61h dynamic-entry analysis.
