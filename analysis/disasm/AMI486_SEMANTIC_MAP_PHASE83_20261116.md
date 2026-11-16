# AMI486 semantic map — phase 83 (2026-11-16)

## 1. Additional direct-port read of CMOS[8Eh]

The phase82 helper-call inventory is not the entire set of reads. A separate direct-port sequence exists at 834Fh:

```asm
834F  MOV AL,8Eh
8351  OUT 70h,AL
8353  JCXZ 8355h
8355  JCXZ 8357h
8357  IN AL,71h
8359  MOV AH,AL
835B  CS: MOV AL,[BX+1Ch]
835F  CS: MOV BL,[BX+1Dh]
8363  TEST AH,C0h
8366  JNZ 8374h
8368  OR AL,80h
836A  OUT 70h,AL
836C  JCXZ 836Eh
836E  JCXZ 8370h
8370  IN AL,71h
8372  JMP 8397h
```

The direct access reads CMOS[8Eh] and preserves the returned byte in AH. If either bit 6 or bit 7 is set, execution skips the conditional secondary read. If both are clear, it takes the index byte from the CS-relative table at [BX+1Ch], sets bit 7 of that index, selects it through port 70h and reads its data through port 71h.

This is a different caller from the EE94h helper users. The C0h mask is reused, but the downstream operation is a conditional read from a table-selected CMOS index.

## 2. Immediate writer search

A raw scan for immediate index setup found:
- thirteen `MOV AL,8Eh; CALL EE94h` sequences listed in phase82;
- one direct `MOV AL,8Eh; OUT 70h,AL` sequence at 834Fh;
- no immediate `MOV AL,8Eh; CALL EE9Dh` write-helper sequence.

The direct 834Fh sequence reads port 71h after selecting 8Eh; it does not write port 71h. Therefore no immediate direct write to CMOS[8Eh] has been established by these patterns.

This is not proof that CMOS[8Eh] is never written: indirect index values, register-based CMOS helpers, and data-driven writes remain possible. The raw scan only excludes the specific immediate forms above.

## 3. Surrounding routine context

The sequence is embedded in a CS-relative table/parameter walker beginning before 834Fh. It uses BX as a table cursor, checks a table field at [BX+1Fh], advances the cursor in 20h-sized steps, and later compares fields against CS-relative data. The repeated structure around 83B0h..83F0h appears to be a second/related walker. The precise table schema and its entry callers remain to be established.

## 4. Updated conclusions

CMOS[8Eh] has at least fourteen confirmed read sites: thirteen through EE94h and one direct port-70h/71h read at 834Fh. Several independent subsystems test C0h, but the common mask alone does not establish identical semantics. No immediate 8Eh writer has yet been confirmed.

Still open: register-indexed CMOS writes to 8Eh, the table schema around 8324h..83F0h, individual 8Eh bit meanings, BEh:BFh update ordering, BP.13 provenance, and dynamic entry into DA5Eh/DA61h.
