param(
    [Parameter(Mandatory = $true)]
    [string]$RomPath,
    [Parameter(Mandatory = $true)]
    [int]$ExpectedSize,
    [Parameter(Mandatory = $false)]
    [string]$ReferenceRomPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "BIOS output not found: $RomPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RomPath)
if ($bytes.Length -ne $ExpectedSize -or $ExpectedSize -ne 65536) {
    throw ("Invalid BIOS size: {0}; expected 65536 bytes" -f $bytes.Length)
}

function Assert-Bytes {
    param([int]$Offset, [byte[]]$Expected, [string]$Description)
    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Expected[$i]) {
            throw ("{0}: mismatch at ROM offset 0x{1:X4}; got 0x{2:X2}, expected 0x{3:X2}" -f $Description, ($Offset + $i), $bytes[$Offset + $i], $Expected[$i])
        }
    }
}

# These checks validate the assembled instruction stream, not a reference ROM.
Assert-Bytes -Offset 0xFFF0 -Expected ([byte[]](0xEA, 0x5B, 0xE0, 0x00, 0xF0)) -Description "NASM reset far jump"
Assert-Bytes -Offset 0xE05B -Expected ([byte[]](0xE9, 0xA6, 0xF5)) -Description "NASM reset gateway"
Assert-Bytes -Offset 0xD604 -Expected ([byte[]](0xFA, 0xFC, 0xE4, 0x64, 0xA8, 0x04, 0x75, 0x06, 0xE9)) -Description "NASM POST entry"
Assert-Bytes -Offset 0x88CE -Expected ([byte[]](0xB9, 0x00, 0x01, 0xE2, 0xFE, 0x8C, 0xC8, 0x8E, 0xD0, 0x0F, 0x01, 0xE0, 0xA8, 0x01, 0x75, 0x40)) -Description "NASM 8042 reset entry"
Assert-Bytes -Offset 0x88EE -Expected ([byte[]](0xF0, 0x88)) -Description "NASM 8042 stack return word"
Assert-Bytes -Offset 0x8A04 -Expected ([byte[]](0x0F, 0x01, 0xE0, 0xA8, 0x01, 0x74, 0x0F, 0xB0, 0x8F, 0xE6, 0x70)) -Description "NASM CMOS reset branch"
Assert-Bytes -Offset 0x8A20 -Expected ([byte[]](0x8B, 0xC6, 0x3C, 0x05, 0x74, 0x08, 0x3C, 0x09, 0x74, 0x04, 0x3C, 0x0A, 0x75, 0x42)) -Description "NASM CMOS marker dispatcher"
Assert-Bytes -Offset 0xD6A8 -Expected ([byte[]](0x24, 0xD7, 0xD1, 0x91, 0x1E, 0xF7, 0x80, 0x52, 0x24, 0xF7, 0x31, 0xF7, 0x86, 0x54, 0x5B, 0x1B, 0x1D, 0x8A, 0x06, 0x92, 0x37, 0xF7)) -Description "NASM CMOS 8Fh semantic jump table"
Assert-Bytes -Offset 0xD6BE -Expected ([byte[]](0xBD, 0x05, 0x00, 0xE9, 0xE1, 0x1D)) -Description "NASM stack test failure handler"
Assert-Bytes -Offset 0xD6DE -Expected ([byte[]](0xB0, 0x01, 0xE6, 0x80, 0xBC, 0x55, 0x55, 0x81, 0xFC, 0x55, 0x55, 0x75, 0xD3)) -Description "NASM stack integrity test entry"
Assert-Bytes -Offset 0xD6FC -Expected ([byte[]](0x35, 0x55, 0x55, 0x75, 0xBD, 0xB8, 0xAA, 0xAA, 0xBC, 0x09, 0xD7, 0xEB, 0xB9)) -Description "NASM stack integrity continuation"

Write-Host ("NASM BIOS structural validation PASS: {0} bytes; reset vector, gateway and POST instruction encoding verified. This does not validate POST completion or boot." -f $bytes.Length) -ForegroundColor Green
