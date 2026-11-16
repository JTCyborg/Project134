#!/usr/bin/env python3
"""Emit bounded Capstone decodes from raw-byte candidate offsets.

These are inspection windows, NOT confirmed function entries or a CFG.
Data ranges (the A125h prompt and AD00h-AE5Fh key maps) are excluded.
Each stream is independently decoded to preserve alternate starts.
"""
from pathlib import Path
from capstone import Cs, CS_ARCH_X86, CS_MODE_16
from capstone.x86_const import X86_OP_IMM

ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "ami486.bin"
OUT_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.txt"
MANIFEST_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.manifest.txt"
WINDOW = 0x80

SEEDS = [
    (0xA000, "code-dense raw window; entry not yet caller-verified"),
    (0xA080, "continuation candidate after initial A000h helper group"),
    (0xA08D, "INT 13h hard-disk handler entry; forwards DL<80h to INT 40h"),
    (0xA0A0, "INT 13h AH-function dispatcher prologue"),
    (0xA0BD, "indirect CALL through CS-relative 26-entry function table"),

    (0xA18E, "byte-aligned short helper immediately after embedded prompt"),
    (0xA197, "branch target from A19Ah; likely routine entry"),
    (0xA1A4, "independent routine entry"),
    (0xA2F1, "direct CALL target; ATA geometry/parameter helper"),
    (0xA1B3, "branch target from A19Ch; ATA controller initialization path"),
    (0xA20B, "status-return helper after A20Ah RET"),
    (0xA216, "routine entry after A215h RET"),
    (0xA226, "routine entry after A225h RET"),
    (0xA23E, "routine entry after A23Dh RET"),
    (0xA25F, "routine entry after A25Eh RET"),
    (0xA300, "geometry/parameter conversion candidate"),
    (0xA337, "direct CALL target"),
    (0xA372, "direct dispatch target"),
    (0xA406, "direct jump target; ATA data transfer path"),
    (0xA474, "routine entry after A473h RET"),
    (0xA501, "direct CALL target; ATA command path"),
    (0xA5A9, "direct CALL target; ATA parameter helper"),
    (0xA5B6, "direct CALL target; ATA geometry helper"),
    (0xA5CA, "direct CALL target; ATA readiness/helper"),
    (0xA694, "direct CALL target; ATA status wait"),
    (0xA6BB, "direct CALL target; ATA transfer/status helper"),
    (0xA6DC, "direct CALL target; ATA status completion helper"),
    (0xA52B, "routine entry after A52Ah RET"),
    (0xA552, "direct CALL target"),
    (0xA57B, "routine entry after A57Ah RET"),
    (0xA610, "continuation near ATA status helper"),
    (0xA619, "routine entry after A618h RET"),
    (0xA621, "direct CALL target; ATA feature/error register write"),
    (0xA62D, "direct CALL target; ATA status polling"),
    (0xA655, "direct CALL target; ATA drive/status check"),
    (0xA703, "ATA error/status decode candidate"),
    (0xA73E, "direct CALL target; ATA command register write"),
    (0xA76C, "direct CALL target; ES:BX buffer normalization"),
    (0xA798, "direct CALL target; ATA transfer setup"),
    (0xA7BA, "direct CALL target; ATA transfer helper"),
    (0xA798, "direct CALL target; ATA transfer setup"),
    (0xA7BA, "direct CALL target; ATA transfer helper"),
    (0xA808, "direct CALL target; mode/compatibility check"),
    (0xA80F, "direct CALL target; prompt decision path"),
    (0xA847, "direct CALL target; BIOS display/input prompt"),
    (0xA8C7, "prompt continuation / input decision candidate"),
    (0xA95E, "candidate IVT hook installation stream"),
    (0xAA00, "INT 13h disk-service path candidate"),
    (0xAA6F, "direct CALL target; INT 13h drive parameter query"),
    (0xAB34, "routine entry after AB33h RET; disk metadata path"),
    (0xAC00, "ATA identify/read transfer path candidate"),
    (0xAE60, "code resumes after keyboard translation table candidate"),
    (0xAF00, "keyboard/BIOS event handling code candidate"),
    (0x2100, "5555h/AAAAh pattern-write and compare stream candidate"),
    (0x6800, "code-dense raw window without phase address token"),
    (0xD100, "FDC I/O code candidate; references ports 03F4h/03F7h"),
    (0xD200, "FDC I/O continuation candidate"),
    (0xD300, "FDC I/O continuation candidate"),
    (0xD400, "FDC I/O continuation candidate"),
    (0xD294, "direct CALL target; FDC result/data read helper"),
    (0xD500, "FDC I/O continuation candidate"),
    (0xD580, "FDC command completion continuation"),
    (0xD5DB, "FDC routine continuation / return path"),
    (0xF900, "interrupt/dispatch wrapper candidate; indirect-call provenance unresolved"),
    (0xF936, "target listed in F92Ah dispatch table"),
    (0xF977, "target listed in F92Ah dispatch table"),
    (0xF986, "target listed in F92Ah dispatch table"),
    (0xF999, "target listed in F92Ah dispatch table"),
    (0xF9C4, "target listed in F92Ah dispatch table"),
    (0xF9D3, "target listed in F92Ah dispatch table"),
]

def main():
    rom = ROM_PATH.read_bytes()
    if len(rom) != 65536:
        raise SystemExit(f"Expected 65536 bytes, got {len(rom)}")
    md = Cs(CS_ARCH_X86, CS_MODE_16)
    md.detail = True
    lines = [
        "AMI486 RAW-BYTE CANDIDATE WINDOWS",
        "Decoder: Capstone x86 16-bit",
        "Window length: 0x80 bytes per seed, clipped at ROM end",
        "WARNING: independently seeded linear decodes; not a CFG and not proof of entry points.",
        "Relative near-branch targets are normalized to 16-bit IP wraparound.",
        "",
    ]
    for start, reason in SEEDS:
        end = min(start + WINDOW, len(rom))
        lines += [f"===== {start:04X}h-{end-1:04X}h =====", f"Reason: {reason}"]
        off = start
        while off < end:
            ins = next(md.disasm(rom[off:end], off, count=1), None)
            if ins is None or ins.size < 1:
                b = rom[off]
                lines.append(f"{off:04X}  {b:02X}              db 0x{b:02X}")
                off += 1
            else:
                raw = rom[off:off + ins.size]
                op_str = ins.op_str
                b = ins.bytes
                relative = (
                    b[0] in (0xE8, 0xE9, 0xEB)
                    or 0x70 <= b[0] <= 0x7F
                    or 0xE0 <= b[0] <= 0xE3
                    or (len(b) >= 2 and b[0] == 0x0F and 0x80 <= b[1] <= 0x8F)
                )
                if relative and ins.operands and ins.operands[0].type == X86_OP_IMM:
                    op_str = f"0x{ins.operands[0].imm & 0xFFFF:x}"
                lines.append(f"{off:04X}  {raw.hex(' ').upper():<23} {ins.mnemonic} {op_str}".rstrip())
                off += ins.size
        lines.append("")
    OUT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    MANIFEST_PATH.write_text(
        "Target: ami486.bin\n"
        "ROM size: 65536 bytes\n"
        f"Candidate windows: {len(SEEDS)}\n"
        f"Window bytes: 0x{WINDOW:X} each (clipped at ROM end)\n"
        "Decoder: Capstone x86 16-bit\n"
        "Relative near-branch targets normalized to 16-bit IP.\n"
        "Interpretation: independently seeded linear windows only; no CFG or entry-point proof.\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(SEEDS)} candidate windows to {OUT_PATH}")

if __name__ == "__main__":
    main()
