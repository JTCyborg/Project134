#!/usr/bin/env python3
"""Emit bounded Capstone decodes from raw-byte candidate offsets.

These are inspection windows, NOT confirmed function entries or a CFG.
Known tables/strings are emitted as data and excluded from code windows.
"""
from pathlib import Path
from capstone import Cs, CS_ARCH_X86, CS_MODE_16
from capstone.x86_const import X86_OP_IMM

ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = ROOT / "ami486.bin"
OUT_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.txt"
MANIFEST_PATH = ROOT / "analysis" / "disasm" / "ami486_candidate_windows_20261116.manifest.txt"
WINDOW = 0x80
LIMITS = {0xA08D: 0x64, 0xA0A0: 0x51, 0xA0BD: 0x34, 0xE845: 0x20}

DATA_RANGES = [
    (0xA0F1, 0xA125, "INT 13h AH function table", "words"),
    (0xA125, 0xA18E, "Format / BootSector Write / Possible VIRUS prompt", "ascii"),
    (0xAD00, 0xAE60, "Keyboard translation data candidates", "hexascii"),
    (0xF92A, 0xF936, "F9xx indirect-handler offset table", "words"),
    (0xE401, 0xE481, "First eight 16-byte fixed-disk parameter records", "hexascii"),
]

SEEDS = [
    (0xA000, "code-dense raw window; entry not yet caller-verified"),
    (0xA080, "continuation candidate after initial A000h helper group"),
    (0xA08D, "INT 13h hard-disk handler entry; forwards DL<80h to INT 40h"),
    (0xA0A0, "INT 13h AH-function dispatcher prologue"),
    (0xA0BD, "indirect CALL through CS-relative 26-entry function table"),
    (0xA0A0, "candidate routine prologue and local stack frame"),
    (0xA18E, "byte-aligned short helper immediately after embedded prompt"),
    (0xA197, "branch target from A19Ah; likely routine entry"),
    (0xA1A4, "independent routine entry"),
    (0xA1B3, "branch target from A19Ch; ATA controller initialization path"),
    (0xA20B, "status-return helper after A20Ah RET"),
    (0xA216, "routine entry after A215h RET"),
    (0xA226, "routine entry after A225h RET"),
    (0xA23E, "routine entry after A23Dh RET"),
    (0xA25F, "routine entry after A25Eh RET"),
    (0xA2F1, "direct CALL target; ATA geometry/parameter helper"),
    (0xA300, "geometry/parameter conversion candidate"),
    (0xA337, "direct CALL target"),
    (0xA372, "direct dispatch target"),
    (0xA406, "direct jump target; ATA data transfer path"),
    (0xA474, "routine entry after A473h RET"),
    (0xA501, "direct CALL target; ATA command path"),
    (0xA5A9, "direct CALL target; ATA parameter helper"),
    (0xA5B6, "direct CALL target; ATA geometry helper"),
    (0xA5CA, "direct CALL target; ATA readiness/helper"),
    (0xA52B, "routine entry after A52Ah RET"),
    (0xA552, "direct CALL target"),
    (0xA57B, "routine entry after A57Ah RET"),
    (0xA610, "continuation near ATA status helper"),
    (0xA619, "routine entry after A618h RET"),
    (0xA621, "direct CALL target; ATA feature/error register write"),
    (0xA62D, "direct CALL target; ATA status polling"),
    (0xA655, "direct CALL target; ATA drive/status check"),
    (0xA694, "direct CALL target; ATA wait helper"),
    (0xA6BB, "direct CALL target; ATA transfer/status helper"),
    (0xA6DC, "direct CALL target; ATA status completion helper"),
    (0xA703, "ATA error/status decode candidate"),
    (0xA73E, "direct CALL target; ATA command register write"),
    (0xA76C, "direct CALL target; ES:BX buffer normalization"),
    (0xA798, "direct CALL target; ATA transfer setup"),
    (0xA7BA, "direct CALL target; ATA transfer helper"),
    (0xA808, "direct CALL target; mode/compatibility check"),
    (0xA80F, "direct CALL target; prompt decision path"),
    (0xA847, "direct CALL target; BIOS display/input prompt"),
    (0xA8C7, "prompt continuation / input decision candidate"),
    (0xA95E, "candidate INT 13h IVT hook installation stream"),
    (0xAA00, "INT 13h disk-service path candidate"),
    (0xAA6F, "direct CALL target; INT 13h drive parameter query"),
    (0xAB34, "routine entry after AB33h RET; disk metadata path"),
    (0xAC00, "ATA identify/read transfer path candidate"),
    (0xAE60, "INT 15h keyboard-intercept wrapper candidate after translation tables"),
    (0xAEE3, "keyboard-intercept branch target / common continuation"),
    (0xAF06, "keyboard event handler continuation"),
    (0xB1E9, "keyboard-intercept common exit target"),
    (0xB242, "keyboard event classifier direct CALL target"),
    (0xB253, "keyboard event state helper direct CALL target"),
    (0xB25F, "keyboard event state helper direct CALL target"),
    (0xB273, "keyboard-intercept helper direct CALL target"),
    (0xB296, "keyboard-intercept helper direct CALL target"),
    (0xB315, "keyboard event state helper direct CALL target"),
    (0xB327, "keyboard event state helper direct CALL target"),
    (0xB3D2, "keyboard event state helper direct CALL target"),
    (0xB3E2, "BIOS INT 16h keyboard-service handler entry candidate"),
    (0xB3DE, "keyboard interrupt/event continuation"),
    (0xB399, "BIOS keyboard ring-buffer pointer helper"),
    (0xB3A6, "keyboard controller status/command helper"),
    (0xB36A, "8042 keyboard command-byte sender with retry"),
    (0xB413, "INT 16h keyboard-buffer status path"),
    (0xB431, "INT 16h typematic-rate setup path"),
    (0xB473, "INT 16h keyboard read path candidate"),
    (0xB478, "INT 16h keyboard status path candidate"),
    (0xB480, "INT 16h keyboard service continuation"),
    (0xB48A, "INT 16h keyboard service continuation"),
    (0xB3D8, "keyboard event state helper direct CALL target"),
    (0xAF00, "keyboard/BIOS event handling code candidate"),
    (0x2100, "5555h/AAAAh pattern-write and compare stream candidate"),
    (0x2187, "memory-pattern test failure/return target"),
    (0x222D, "memory-pattern failure trampoline with crafted stack frame"),
    (0x2253, "second memory-pattern probe stream"),
    (0x22DB, "second memory-pattern probe failure trampoline"),
    (0x6800, "code-dense raw window without phase address token"),
    (0xD100, "FDC I/O code candidate; references ports 03F4h/03F7h"),
    (0xD104, "FDC media/drive-state helper candidate"),
    (0xD156, "direct DMA programming helper"),
    (0xC648, "candidate main diskette BIOS dispatcher before FDC helper calls"),
    (0xC8BB, "direct caller of DMA channel-2 setup D156h"),
    (0xC936, "direct caller of DMA channel-2 setup D156h"),
    (0xD1C0, "direct FDC state/reset helper"),
    (0xD200, "FDC I/O continuation candidate"),
    (0xD216, "FDC/DMA transaction coordinator"),
    (0xD243, "FDC FIFO command-byte writer"),
    (0xD270, "FDC result-byte collection loop"),
    (0xD300, "FDC I/O continuation candidate"),
    (0xD2BD, "FDC status-byte to BIOS error mapper"),
    (0xD2FD, "FDC reset/status path"),
    (0xD348, "FDC digital-output-register reset sequence"),
    (0xD3A3, "FDC controller state helper"),
    (0xD3A5, "FDC controller state helper"),
    (0xD3B5, "FDC drive-state helper"),
    (0xD3ED, "FDC command sequence entry candidate"),
    (0xD3FA, "FDC command sequence common path"),
    (0xD400, "FDC I/O continuation candidate"),
    (0xD499, "FDC FIFO command helper"),
    (0xD500, "FDC I/O continuation candidate"),
    (0xD520, "FDC multi-byte result validation"),
    (0xD517, "FDC configuration-control register writer"),
    (0xD294, "direct CALL target; FDC result/data read helper"),
    (0xD580, "FDC command completion continuation"),
    (0xD5DB, "FDC routine continuation / return path"),
    (0xE845, "INT 76h / IRQ14 handler installed by A95Eh"),
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
        "Window length: 0x80 bytes by default; selected handler windows stop at known data boundaries",
        "WARNING: independently seeded linear decodes; not a CFG and not proof of entry points.",
        "Relative near-branch targets are normalized to 16-bit IP wraparound.",
        "",
    ]
    for start, end, label, kind in DATA_RANGES:
        raw = rom[start:end]
        lines += [f"===== DATA {start:04X}h-{end-1:04X}h =====", f"Reason: {label}"]
        if kind == "words":
            words = [int.from_bytes(raw[i:i+2], "little") for i in range(0, len(raw), 2)]
            lines.append("Words: " + ", ".join(f"{w:04X}" for w in words))
        elif kind == "ascii":
            lines.append("ASCII: " + repr(raw.decode("ascii", errors="replace")))
        else:
            for pos in range(0, len(raw), 16):
                chunk = raw[pos:pos+16]
                asc = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
                lines.append(f"{start+pos:04X}  {chunk.hex(' ').upper():<47} {asc}")
        lines.append("")
    seen = set()
    for start, reason in SEEDS:
        if start in seen:
            continue
        seen.add(start)
        end = min(start + LIMITS.get(start, WINDOW), len(rom))
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
        f"Candidate windows: {len(seen)}\n"
        f"Window bytes: 0x{WINDOW:X} default; selected handler windows clipped at known data boundaries\n"
        "Decoder: Capstone x86 16-bit\n"
        "Relative near-branch targets normalized to 16-bit IP.\n"
        "Known tables and strings are emitted separately as data.\n"
        "Interpretation: independently seeded linear windows only; no CFG or entry-point proof.\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(seen)} candidate windows to {OUT_PATH}")

if __name__ == "__main__":
    main()
