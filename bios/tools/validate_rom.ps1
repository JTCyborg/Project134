param(
    [Parameter(Mandatory = $true)]
    [string]$RomPath,

    [Parameter(Mandatory = $true)]
    [int]$ExpectedSize,

    [Parameter(Mandatory = $true)]
    [string]$ReferenceRomPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "BIOS output not found: $RomPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RomPath)

if (-not (Test-Path -LiteralPath $ReferenceRomPath -PathType Leaf)) {
    throw "Immutable reference ROM not found: $ReferenceRomPath"
}

$referenceBytes = [System.IO.File]::ReadAllBytes($ReferenceRomPath)
if ($referenceBytes.Length -ne 65536) {
    throw ("Invalid reference ROM size: {0} bytes; expected 65536" -f $referenceBytes.Length)
}

$referenceHash = (Get-FileHash -LiteralPath $ReferenceRomPath -Algorithm SHA256).Hash.ToLowerInvariant()
$expectedReferenceHash = "91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b"
if ($referenceHash -ne $expectedReferenceHash) {
    throw ("Reference ROM identity mismatch: SHA-256 {0}" -f $referenceHash)
}
if ($bytes.Length -ne $ExpectedSize) {
    throw ("Invalid ROM size: {0} bytes; expected {1}" -f $bytes.Length, $ExpectedSize)
}
if ($ExpectedSize -ne 65536) {
    throw "The current AMI486 reconstruction layout requires a 64 KiB ROM."
}

function Assert-Bytes {
    param([int]$Offset, [byte[]]$Expected, [string]$Description)
    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Expected[$i]) {
            throw ("{0}: mismatch at ROM offset 0x{1:X4}; got 0x{2:X2}, expected 0x{3:X2}" -f $Description, ($Offset + $i), $bytes[$Offset + $i], $Expected[$i])
        }
    }
}


# Verify the reset-continuation branch at 8A04h byte-for-byte.
for ($offset = 0x8A04; $offset -lt 0x8A20; $offset++) {
    if ($bytes[$offset] -ne $referenceBytes[$offset]) {
        throw ("Reset continuation byte mismatch at 0x{0:X4}: output 0x{1:X2}, reference 0x{2:X2}" -f $offset, $bytes[$offset], $referenceBytes[$offset])
    }
}

# Verify additional early reset/POST dispatch and hardware helper windows.
for ($offset = 0x8A20; $offset -lt 0x8A75; $offset++) {
    if ($bytes[$offset] -ne $referenceBytes[$offset]) {
        throw ("Reference-window mismatch at 0x{0:X4}: output 0x{1:X2}, reference 0x{2:X2}" -f $offset, $bytes[$offset], $referenceBytes[$offset])
    }
}

for ($offset = 0x8CCD; $offset -lt 0x8DEC; $offset++) {
    if ($bytes[$offset] -ne $referenceBytes[$offset]) {
        throw ("Reference-window mismatch at 0x{0:X4}: output 0x{1:X2}, reference 0x{2:X2}" -f $offset, $bytes[$offset], $referenceBytes[$offset])
    }
}

for ($offset = 0xEE94; $offset -lt 0xEF36; $offset++) {
    if ($bytes[$offset] -ne $referenceBytes[$offset]) {
        throw ("Reference-window mismatch at 0x{0:X4}: output 0x{1:X2}, reference 0x{2:X2}" -f $offset, $bytes[$offset], $referenceBytes[$offset])
    }
}

# Verify the reconstructed POST bytes byte-for-byte against the immutable ROM.
# D604h-D6A6h is the entry dispatcher; D6A7h-D776h is its continuation/helper.
for ($offset = 0xD604; $offset -lt 0xD777; $offset++) {
    if ($bytes[$offset] -ne $referenceBytes[$offset]) {
        throw ("Early POST byte mismatch at 0x{0:X4}: output 0x{1:X2}, reference 0x{2:X2}" -f $offset, $bytes[$offset], $referenceBytes[$offset])
    }
}

# Reference reset vector: EA 5B E0 00 F0 => F000:E05B.
Assert-Bytes -Offset 0xFFF0 -Expected ([byte[]](0xEA, 0x5B, 0xE0, 0x00, 0xF0)) -Description "Reset vector"
# Reference reset gateway at F000:E05B: E9 A6 F5 => near JMP D604.
Assert-Bytes -Offset 0xE05B -Expected ([byte[]](0xE9, 0xA6, 0xF5)) -Description "Reset gateway"
# First instructions at D604 are the verified CLI/CLD/8042 status probe.
Assert-Bytes -Offset 0xD604 -Expected ([byte[]](0xFA, 0xFC, 0xE4, 0x64, 0xA8, 0x04, 0x75, 0x06)) -Description "Early POST entry"

Write-Host ("BIOS ROM validation PASS: {0} bytes; reference SHA-256 verified; 8A04h-8A1Fh, 8A20h-8A74h, 8CCDh-8DEBh, EE94h-EF35h and D604h-D776h byte matches; FFFF:0000 -> F000:E05B -> D604h" -f $bytes.Length) -ForegroundColor Green
