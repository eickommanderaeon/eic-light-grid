Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$targets = @(
  (Join-Path (Get-Location).Path 'codex\LIGHT_GRID_CODEX\covenants\Covenant-Infinity.md'),
  (Join-Path (Get-Location).Path 'codex\LIGHT_GRID_CODEX\index.md')
)

# Try code.cmd from user-local install first
$codeCmd = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'
if (Test-Path $codeCmd) {
  Start-Process -FilePath $codeCmd -ArgumentList (@('-g') + $targets) | Out-Null
  Start-Process -FilePath $codeCmd -ArgumentList '.' | Out-Null
  Write-Host 'Opened covenant, index, and folder in VS Code (code.cmd).'
  exit 0
}

$codeCandidates = @(
  (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
  'C:\\Program Files\\Microsoft VS Code\\Code.exe',
  'C:\\Program Files (x86)\\Microsoft VS Code\\Code.exe'
)

$codePath = $null
foreach ($c in $codeCandidates) {
  if (Test-Path $c) { $codePath = $c; break }
}

if (-not $codePath) {
  $searchRoots = @(
    (Join-Path $env:LOCALAPPDATA 'Programs'),
    'C:\\Program Files',
    'C:\\Program Files (x86)'
  )
  try {
    $found = Get-ChildItem -Path $searchRoots -Filter 'Code.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $codePath = $found.FullName }
  } catch {}
}

if (-not $codePath) {
  throw 'VS Code (Code.exe) not found. Add "code" to PATH from VS Code or provide install path.'
}

$argsList = @('-g') + $targets
Start-Process -FilePath $codePath -ArgumentList $argsList | Out-Null
Start-Process -FilePath $codePath -ArgumentList '.' | Out-Null
Write-Host 'Opened covenant, index, and folder in VS Code.'
