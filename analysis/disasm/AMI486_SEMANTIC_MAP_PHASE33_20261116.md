# AMI486 semantic map — phase 33 (2026-11-16)

## 1. Corrected interpretation of the small tables at 8E4Eh and 8E76h

The 1B22h loop reads one word at a time with LODSW and passes AX through the stack-return trampoline to 8DDCh. The helper at 8DDCh performs:

- OUT 22h, AL — select ALi register index;
- XCHG AL,AH;
- OUT 23h, AL — write the original AH as register data;
- XCHG AL,AH; RET.

Therefore each table word is a direct byte pair `register-index, register-value`, not an instruction and not a pair of separate words.

The table selected when CMOS B3h bit 2 is set is exactly 10 words at 8E4Eh–8E61h:

| Offset | ALi index | Value |
|---|---:|---:|
| 8E4E | C0h | 21h |
| 8E50 | C1h | 00h |
| 8E52 | C5h | 00h |
| 8E54 | C6h | 0Fh |
| 8E56 | C8h | 00h |
| 8E58 | C9h | 00h |
| 8E5A | CBh | 00h |
| 8E5C | CCh | 00h |
| 8E5E | CEh | 00h |
| 8E60 | CFh | 00h |

The table selected when CMOS B3h bit 2 is clear is two words at 8E76h–8E79h:

| Offset | ALi index | Value |
|---|---:|---:|
| 8E76 | 00h | C1h |
| 8E78 | 00h | C2h |

The earlier phase32 report's first-table range and the interpretation of its entries have now been corrected. These are byte-pair register writes, not executable instructions.

## 2. The larger table at 8750h is a different encoding

At 208Dh the loop computes a count of (87A4h-8750h)/4 = 21 entries. Each entry occupies four bytes and is consumed as two words:

1. LODSW reads the first word; its low byte is reduced by 30h. That result is retained in BL and compared with 26h. If equal, the entry is skipped.
2. Otherwise the next word is read with LODSW. Its high byte remains in AH; AL is replaced with the transformed first-byte value in BL.
3. The pair AX is passed to 8DDCh, which writes AL to ALi index port 22h and AH to data port 23h.

Thus the larger table is an array of 4-byte records: first word contains an encoded register selector in its low byte; second word supplies the register value in its high byte. The low-byte selector transform is `encoded_selector - 30h`. Entries resolving to 26h are deliberately skipped. The exact meaning of the high/low unused bytes is not established by this loop.

This is distinct from the small direct-pair tables at 8E4Eh and 8E76h.

## 3. CMOS B3h selection and sequencing

At 1AFBh the BIOS requests CMOS index B3h via EE94h. On return:
- bit 2 set -> writes the ten direct pairs from 8E4Eh;
- bit 2 clear -> writes the two direct pairs from 8E76h.

After these writes, it programs port 61h, port 8Fh, PIT control port 43h, PIT channel data port 41h, fills 400h bytes at ES:DI, and jumps to 208Dh for the separate 21-record 8750h table and memory probe.

This proves B3h bit 2 selects between two ALi register-write profiles. It does not, by itself, establish a user-facing setting name or the hardware meaning of each register.

## 4. Scope and open questions

- ALi register names/semantics for C0h, C1h, C5h, C6h, C8h, C9h, CBh, CCh, CEh, CFh and register 00h remain unknown without a reliable ALi1429 register map.
- The 8750h–87A3h table still needs to be decoded into all 21 transformed index/value writes and correlated with ALi documentation.
- The upstream entry into the 1AFBh trampoline remains unresolved.
- The memory-probe outcomes in registers 10h/11h remain ordinal alias-test results, not proven capacity values.

## 5. Evidence correction note

Phase32 originally described the selected small tables as 8E62h/8E76h and interpreted the table loop incompletely. The machine code at 1B0Bh, 1B0Fh, 1B12h, 1B18h, 1B1Bh and 1B22h establishes the correct ranges: 8E4Eh–8E61h and 8E76h–8E79h. The helper at 8DDCh establishes the byte-pair write semantics. This phase supersedes those specific incorrect statements in phase32.
