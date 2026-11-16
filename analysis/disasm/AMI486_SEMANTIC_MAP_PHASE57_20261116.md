# AMI486 semantic map — phase 57 (2026-11-16)

## Scope

Audit the remaining executable-looking BP operations in the POST/initialization region, especially the 1662h–1676h rotate loop and D7xx/D8xx status paths. The objective is to determine whether any of these paths can originate BP.13 or only consume an incoming BP bitmap.

## 1. 1662h–1676h is a read-only 16-bit BP bitmap walk

The sequence is:

```asm
1662  push bp
1663  mov cx,10h
1666  lodsw                 ; next table word -> AX
1668  ror bp,1
166A  jae 1673              ; skip if outgoing bit0 was zero
166C  push si
166D  mov si,ax
166F  call 16C0
1672  pop si
1673  loop 1666
1675  pop bp
1676  test bx,bp
```

Each iteration rotates the incoming 16-bit BP right by one and uses CF to decide whether to process the current table word. The loop runs exactly 16 iterations, so it visits all 16 original BP bits. The table word is passed as SI to 16C0h, which calls 410Eh and F52Eh. BP is explicitly restored at 1675h before the subsequent `TEST BX,BP`.

Consequences:
- ROR BP,1 at 1668h is not a persistent BP update.
- The loop consumes the incoming BP as a 16-bit feature/status bitmap.
- BP.13 can affect which table entry is processed, but this code does not create BP.13.
- The final `TEST BX,BP` checks the restored original bitmap, not the rotated intermediate value.

This is a useful downstream consumer for the still-unresolved BP.13 producer.

## 2. BP.6 time/RTC failure flag is also isolated

At 145Eh the RTC validation failure path ORs BP with 0040h (bit 6), then updates CMOS 8Eh bit 2. At 1576h the subsequent diagnostic check is bracketed by PUSH BP / POP BP (1576h/158Fh), so any BP changes made by helper 8630h do not leak into the caller's BP value.

The later 1662h bitmap walk saves and restores BP independently. Therefore neither helper activity nor the rotate loop explains a persistent bit-13 transition.

## 3. D7xx POST selector paths use BP for explicit status/error codes

The selector-7/8/9/10 dispatch region includes a distinct D724h → D743h path:
- D743h XOR BP,BP initializes BP to zero.
- D760h may OR 1000h (bit 12) if 8042 status port 64h bit 2 is set.
- D76Ch may OR 8000h (bit 15) if BDA 0040:0472 equals 1234h.
- D774h continues to the 8A78h indirect trampoline.

Other error branches set small numeric error codes and jump to F4A5h:
- D794h: BP=9, checksum failure after scanning 8000h words.
- D7F2h: BP=6, keyboard-controller response mismatch, conditional on CS:[8280].7.
- D8B8h: BP=10, response mismatch in the 8042 command/data sequence.

These are explicit fatal POST error codes, not bitmaps. None sets bit 13.

## 4. D8D8h–D8FAh adds only bits 3–5

The code around D8D8h is a continuation from the D8xx 8042/CMOS sequence and merges status into BP:
- D8DCh OR BP,0008h (bit 3)
- D8EEh OR BP,0020h (bit 5)
- D8F3h OR BP,0010h (bit 4)

The branch at D8E7h can leave this block for 868Bh. The local writes in this block do not touch bit 13. This confirms the earlier D8EA/D8xx audit: the block accumulates low status bits, not BP.13.

## 5. Memory-size scan at 2913h is a counter, not a flag source

At 2913h BP is zeroed. The loop at 291Bh–2935h scans successive 64-KiB segment windows and increments BP when the measured difference passes its threshold. At 2937h it copies the count to BX, then sets BP=SP as a frame pointer at 2939h.

Thus BP in this routine is a temporary segment-count accumulator. The result is carried in BX; the later BP assignment is stack-frame setup. It does not feed the 5Cxx BP status test as a direct persistent flag producer.

## 6. Complete result for the newly audited candidates

| Address | BP operation | Interpretation |
|---|---|---|
| 145Eh | OR BP,0040h | RTC/time validation status bit 6 |
| 1576h–158Fh | PUSH/POP BP | isolate helper's BP changes |
| 1668h–1675h | ROR BP,1 ×16; POP BP | read-only bitmap walk; original BP restored |
| D743h | XOR BP,BP | initialize status for selector-0 path |
| D760h | OR BP,1000h | bit 12 |
| D76Ch | OR BP,8000h | bit 15 |
| D794h | MOV BP,9 | fatal checksum error code |
| D7F2h | MOV BP,6 | fatal keyboard-controller error code |
| D8B8h | MOV BP,10 | fatal 8042 response error code |
| D8DCh | OR BP,8 | bit 3 |
| D8EEh | OR BP,20h | bit 5 |
| D8F3h | OR BP,10h | bit 4 |
| 2913h | XOR BP,BP; INC BP loop | temporary memory-size count, copied to BX |

None of these newly verified producers sets 2000h.

## 7. Updated conclusion

The 1662h–1676h routine proves that BP is deliberately treated as a 16-bit status bitmap by at least one POST consumer. Bit 13 is therefore semantically meaningful to the BIOS even though its producer has not yet been located.

The best remaining hypothesis is that BP.13 arrives from a caller-supplied or restored status word before the 5Cxx test/bitmap consumer. The 12D3h–12D4h restore/mask path remains a separate path-local observation; no runtime ordering has been established between it and the DAxx/5Cxx chain.

### Confirmed
- 1668h rotates BP to inspect all 16 bits, but 1675h restores BP before further use.
- BP.13 is consumed as part of a full 16-bit status bitmap.
- The D7xx/D8xx audited branches set bits 3–5, 12, 15 or numeric fatal codes; none sets bit 13.
- 2913h–2939h uses BP as a temporary memory-size counter then frame pointer.

### Unresolved
- The upstream source word for BP.13.
- The caller and entry mechanism for the DAxx/5Cxx path.
- Whether the saved/masked BP at 12D3h–12D4h belongs to the same runtime path.
