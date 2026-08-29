# Copy gitignored local config between this repo and a cloud folder (OneDrive).
# Never prints file contents. Skips machine-specific paths (SDK, build, IDE).
# Windows: no Make required. Run from the repo root or via this file's path.
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('export', 'import', 'status', 'set-onedrive', 'help', '')]
    [string] $Action = '',

    [Parameter(Position = 1)]
    [string] $OneDrive = '',

    [string] $Dest = ''
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root

$DestName = 'sprout-local-config'
$DestRelParts = @('Projects', $DestName)
$ManifestName = 'MANIFEST.txt'
$OneDriveFile = '.sprout-onedrive'
$DestFile = '.sprout-local-config-dir'

$CoreFiles = @(
    'sprout_app/assets/config/development.json'
    'sprout_app/assets/config/production.json'
    'sprout_app/android/app/src/development/google-services.json'
    'sprout_app/android/app/src/production/google-services.json'
    'sprout_app/android/key.properties'
    'sprout_app/android/app/release-key.p12'
)

$ExtraFiles = @(
    'sprout_app/assets/config/development.md'
    '.secrets'
)

function Show-Usage {
    @"
Usage:
  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 import -OneDrive `"C:\Users\you\OneDrive`"
  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 set-onedrive -OneDrive `"C:\Users\you\OneDrive`"
  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 status
  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 export

No Make required. Dest is <OneDrive>\Projects\sprout-local-config

Override OneDrive root (first match):
  1. -OneDrive PATH
  2. env SPROUT_ONEDRIVE_DIR
  3. gitignored .sprout-onedrive (set-onedrive)
  4. env OneDrive, then %USERPROFILE%\OneDrive

Override the full dest folder:
  -Dest PATH, env SPROUT_LOCAL_CONFIG_DIR, or .sprout-local-config-dir
"@
}

function Get-Trimmed([string] $Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    return $Value.Trim().Trim('"').Trim("'")
}

function Read-OverrideFile([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    foreach ($line in Get-Content -LiteralPath $Path) {
        $t = Get-Trimmed $line
        if ($t -and -not $t.StartsWith('#')) { return $t }
    }
    return ''
}

function Get-DestFromOneDrive([string] $OneDriveRoot) {
    $root = Get-Trimmed $OneDriveRoot
    return (Join-Path $root (Join-Path $DestRelParts[0] $DestRelParts[1]))
}

function Get-DestFolder {
    param(
        [string] $DestOverride,
        [string] $OneDriveOverride
    )

    $d = Get-Trimmed $DestOverride
    if ($d) { return $d }
    if ($env:DEST) { return (Get-Trimmed $env:DEST) }
    if ($env:SPROUT_LOCAL_CONFIG_DIR) { return (Get-Trimmed $env:SPROUT_LOCAL_CONFIG_DIR) }
    $fromFile = Read-OverrideFile (Join-Path $Root $DestFile)
    if ($fromFile) { return $fromFile }

    $od = Get-Trimmed $OneDriveOverride
    if ($od) { return (Get-DestFromOneDrive $od) }
    if ($env:SPROUT_ONEDRIVE_DIR) { return (Get-DestFromOneDrive $env:SPROUT_ONEDRIVE_DIR) }
    $odFile = Read-OverrideFile (Join-Path $Root $OneDriveFile)
    if ($odFile) { return (Get-DestFromOneDrive $odFile) }

    $roots = @()
    if ($env:OneDrive) { $roots += (Get-Trimmed $env:OneDrive) }
    if ($env:USERPROFILE) {
        $roots += (Join-Path $env:USERPROFILE 'OneDrive')
        $roots += (Join-Path $env:USERPROFILE 'OneDrive - Personal')
    }

    foreach ($root in $roots) {
        if (-not $root) { continue }
        $candidate = Get-DestFromOneDrive $root
        $parent = Split-Path $candidate -Parent
        if ((Test-Path -LiteralPath $candidate) -or (Test-Path -LiteralPath $parent) -or (Test-Path -LiteralPath $root)) {
            return $candidate
        }
    }

    Write-Error @"
Could not find OneDrive. Set it once:

  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 set-onedrive -OneDrive `"C:\Users\you\OneDrive`"
"@
}

function Test-Skipped([string] $Rel) {
    return $Rel -match '(^|/)local\.properties$'
}

function Get-ExportPaths {
    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($f in ($CoreFiles + $ExtraFiles)) {
        if (Test-Path -LiteralPath (Join-Path $Root $f)) { $paths.Add($f) }
    }
    $configDir = Join-Path $Root 'config'
    if (Test-Path -LiteralPath $configDir) {
        Get-ChildItem -LiteralPath $configDir -File -Recurse |
            Where-Object { $_.Name -ne '.DS_Store' } |
            ForEach-Object { $paths.Add($_.FullName.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')) }
    }
    return $paths
}

function Copy-RelFile([string] $SrcRoot, [string] $DstRoot, [string] $Rel) {
    $relWin = $Rel.Replace('/', '\')
    $src = Join-Path $SrcRoot $relWin
    $dst = Join-Path $DstRoot $relWin
    $dir = Split-Path $dst -Parent
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    Copy-Item -LiteralPath $src -Destination $dst -Force
}

function Invoke-Export([string] $DestPath) {
    if (-not (Test-Path -LiteralPath $DestPath)) {
        New-Item -ItemType Directory -Path $DestPath | Out-Null
    }
    $missing = @()
    foreach ($f in $CoreFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root ($f.Replace('/', '\'))))) {
            $missing += $f
        }
    }
    $count = 0
    foreach ($f in (Get-ExportPaths)) {
        if (Test-Skipped $f) { continue }
        Copy-RelFile $Root $DestPath $f
        $count++
        Write-Output "  exported  $f"
    }
    $manifest = @(
        'Sprout local config export'
        "exported_at=$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        "source_host=$env:COMPUTERNAME"
        "file_count=$count"
        ''
    ) + @(Get-ExportPaths)
    Set-Content -LiteralPath (Join-Path $DestPath $ManifestName) -Value $manifest
    Write-Output ""
    Write-Output "Wrote $count files to $DestPath"
    if ($missing.Count -gt 0) {
        Write-Output 'Missing locally (not exported):'
        $missing | ForEach-Object { Write-Output "  $_" }
    }
}

function Read-ManifestPaths([string] $DestPath) {
    $manifest = Join-Path $DestPath $ManifestName
    if (Test-Path -LiteralPath $manifest) {
        return Get-Content -LiteralPath $manifest |
            Where-Object { $_ -and $_ -notmatch '^(Sprout |exported_|source_|file_count)' }
    }
    return Get-ChildItem -LiteralPath $DestPath -File -Recurse |
        Where-Object { $_.Name -notin @('.DS_Store', $ManifestName) } |
        ForEach-Object { $_.FullName.Substring($DestPath.Length).TrimStart('\', '/').Replace('\', '/') }
}

function Invoke-Import([string] $DestPath) {
    if (-not (Test-Path -LiteralPath $DestPath)) {
        Write-Error @"
Export folder not found: $DestPath
Point at this PC's OneDrive root (the folder that contains Projects\):

  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 set-onedrive -OneDrive `"C:\Users\you\OneDrive`"
"@
    }
    $count = 0
    foreach ($f in (Read-ManifestPaths $DestPath)) {
        if ($f -eq $ManifestName) { continue }
        if (Test-Skipped $f) { continue }
        $src = Join-Path $DestPath ($f.Replace('/', '\'))
        if (Test-Path -LiteralPath $src) {
            Copy-RelFile $DestPath $Root $f
            $count++
            Write-Output "  imported  $f"
        }
    }
    Write-Output ""
    Write-Output "Imported $count files into $Root"
}

function Invoke-Status([string] $DestPath) {
    Write-Output "Repo: $Root"
    Write-Output "Dest: $DestPath"
    if (Test-Path -LiteralPath (Join-Path $Root $OneDriveFile)) { Write-Output "Override: $OneDriveFile" }
    if (Test-Path -LiteralPath (Join-Path $Root $DestFile)) { Write-Output "Override: $DestFile" }
    Write-Output ""
    Write-Output ("{0,-10} {1,-10} {2}" -f 'LOCAL', 'DEST', 'PATH')
    foreach ($f in ($CoreFiles + $ExtraFiles)) {
        $loc = if (Test-Path -LiteralPath (Join-Path $Root ($f.Replace('/', '\')))) { 'ok' } else { 'missing' }
        $rem = if (Test-Path -LiteralPath (Join-Path $DestPath ($f.Replace('/', '\')))) { 'ok' } else { 'missing' }
        Write-Output ("{0,-10} {1,-10} {2}" -f $loc, $rem, $f)
    }
    $localConfig = Join-Path $Root 'config'
    $destConfig = Join-Path $DestPath 'config'
    $extras = [System.Collections.Generic.HashSet[string]]::new()
    if (Test-Path -LiteralPath $localConfig) {
        Get-ChildItem -LiteralPath $localConfig -File -Recurse |
            Where-Object { $_.Name -ne '.DS_Store' } |
            ForEach-Object { [void]$extras.Add($_.FullName.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')) }
    }
    if (Test-Path -LiteralPath $destConfig) {
        Get-ChildItem -LiteralPath $destConfig -File -Recurse |
            Where-Object { $_.Name -ne '.DS_Store' } |
            ForEach-Object { [void]$extras.Add($_.FullName.Substring($DestPath.Length).TrimStart('\', '/').Replace('\', '/')) }
    }
    if ($extras.Count -gt 0) {
        Write-Output ""
        Write-Output 'config/ extras:'
        foreach ($f in ($extras | Sort-Object)) {
            $loc = if (Test-Path -LiteralPath (Join-Path $Root ($f.Replace('/', '\')))) { 'ok' } else { 'missing' }
            $rem = if (Test-Path -LiteralPath (Join-Path $DestPath ($f.Replace('/', '\')))) { 'ok' } else { 'missing' }
            Write-Output ("{0,-10} {1,-10} {2}" -f $loc, $rem, $f)
        }
    }
}

function Invoke-SetOneDrive([string] $OneDriveRoot) {
    $root = Get-Trimmed $OneDriveRoot
    if (-not $root) {
        Write-Error 'Usage: scripts\sync-local-config.ps1 set-onedrive -OneDrive "C:\Users\you\OneDrive"'
    }
    Set-Content -LiteralPath (Join-Path $Root $OneDriveFile) -Value $root
    $destPath = Get-DestFromOneDrive $root
    Write-Output "Wrote $OneDriveFile (gitignored)"
    Write-Output "OneDrive: $root"
    Write-Output "Dest:     $destPath"
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Warning 'That OneDrive folder does not exist on this machine yet.'
    }
}

if ($Action -in @('', 'help')) {
    Show-Usage
    exit 0
}

if ($Action -eq 'set-onedrive') {
    Invoke-SetOneDrive $OneDrive
    exit 0
}

$resolved = Get-DestFolder -DestOverride $Dest -OneDriveOverride $OneDrive
Write-Output "$Action → $resolved"
Write-Output ""
switch ($Action) {
    'export' { Invoke-Export $resolved }
    'import' { Invoke-Import $resolved }
    'status' { Invoke-Status $resolved }
}
