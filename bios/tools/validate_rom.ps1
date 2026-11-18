param(
    [Parameter(Mandatory = $true)]
    [string]$RomPath,
    [Parameter(Mandatory = $true)]
    [int]$ExpectedSize,
    [Parameter(Mandatory = $false)]
    [string]$ReferenceRomPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw ('BIOS output not found: {0}' -f $RomPath)
}

$bytes = [System.IO.File]::ReadAllBytes($RomPath)
if ($bytes.Length -ne $ExpectedSize -or $ExpectedSize -ne 65536) {
    throw ('Invalid BIOS size: {0}; expected 65536 bytes' -f $bytes.Length)
}

$referenceMismatchCount = 0
if ($ReferenceRomPath -and (Test-Path -LiteralPath $ReferenceRomPath -PathType Leaf)) {
    $referenceBytes = [System.IO.File]::ReadAllBytes($ReferenceRomPath)
    if ($referenceBytes.Length -ne $ExpectedSize) {
        throw ('Reference ROM has invalid size: {0}; expected {1}' -f $referenceBytes.Length, $ExpectedSize)
    }

    $firstReferenceMismatch = -1
    for ($i = 0; $i -lt $ExpectedSize; $i++) {
        if ($bytes[$i] -ne $referenceBytes[$i]) {
            $referenceMismatchCount++
            if ($firstReferenceMismatch -lt 0) {
                $firstReferenceMismatch = $i
            }
        }
    }

    if ($referenceMismatchCount -eq 0) {
        Write-Host 'FULL ROM BYTE COMPARISON PASS: 65536/65536 bytes match ami486.bin.' -ForegroundColor Green
    }
    else {
        Write-Warning ('FULL ROM BYTE COMPARISON: {0} mismatched bytes; first mismatch at 0x{1:X4} (candidate 0x{2:X2}, reference 0x{3:X2}).' -f $referenceMismatchCount, $firstReferenceMismatch, $bytes[$firstReferenceMismatch], $referenceBytes[$firstReferenceMismatch])
    }

    for ($i = 0x8300; $i -lt 0x8400; $i++) {
        if ($bytes[$i] -ne $referenceBytes[$i]) {
            $contextStart = [Math]::Max(0, $i - 8)
            $contextEnd = [Math]::Min($ExpectedSize - 1, $i + 8)
            $candidateContext = (($contextStart..$contextEnd | ForEach-Object { '{0:X2}' -f $bytes[$_] }) -join ' ')
            $referenceContext = (($contextStart..$contextEnd | ForEach-Object { '{0:X2}' -f $referenceBytes[$_] }) -join ' ')
            throw ('CPU/cache profile mismatch at 0x{0:X4}: candidate=0x{1:X2}, reference=0x{2:X2}; candidate[{3:X4}-{4:X4}]={5}; reference={6}' -f $i, $bytes[$i], $referenceBytes[$i], $contextStart, $contextEnd, $candidateContext, $referenceContext)
        }
    }
    Write-Host 'CPU/cache profile routines 8300h-83FFh match the reference byte-for-byte.' -ForegroundColor Green
}

$wordSum = 0
for ($i = 0; $i -lt $bytes.Length; $i += 2) {
    $wordSum = ($wordSum + [int]$bytes[$i] + ([int]$bytes[$i + 1] * 256)) % 65536
}
if ($wordSum -eq 0) {
    Write-Host 'BIOS POST06 ROM checksum PASS (16-bit sum = 0000h).' -ForegroundColor Green
}
else {
    Write-Warning ('BIOS POST06 ROM checksum FAIL: 16-bit sum = {0:X4}h; reconstructed POST checksum takes its fatal-error branch at F000:F4A5.' -f $wordSum)
}

if ($ReferenceRomPath -and $referenceMismatchCount -gt 0) {
    throw ('Full ROM reference comparison failed: {0} bytes differ.' -f $referenceMismatchCount)
}
Write-Host ('NASM BIOS structural validation PASS: {0} bytes. This does not validate PCem execution.' -f $bytes.Length) -ForegroundColor Green
