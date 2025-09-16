Param(
  [switch]$NoRun # if set, perform checks/fixes only; do not start the API
)
$ErrorActionPreference = "Stop"
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Warning $m }
function Fail($m){ throw $m }
# Paths
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) # .../eic-light-grid
$web  = Join-Path $root "web"
if (-not (Test-Path $web)) { Fail "Project folder not found: $web" }
# Versions for support
Info "Node: $(node -v)"
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
  Info "pnpm: $(pnpm -v)"
} else {
  Fail "pnpm not found. Install from https://pnpm.io/installation"
}
# FFmpeg presence / install hints
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Warn "ffmpeg not found; attempting install via winget…"
    try {
      winget install --id=Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements | Out-Null
    } catch {
      try {
        winget install --id=FFmpeg.FFmpeg -e --accept-source-agreements --accept-package-agreements | Out-Null
      } catch {
        Warn "winget install failed. Install manually or via: choco install ffmpeg"
      }
    }
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
      Warn "ffmpeg may require opening a NEW PowerShell window to refresh PATH."
    } else {
      Info "ffmpeg installed."
    }
  } else {
    Warn "winget not found. Install ffmpeg manually or via: choco install ffmpeg"
  }
} else {
  Info "ffmpeg found."
}
# Free port 7777 if occupied (handle multiple PIDs)
try {
  $pids = (Get-NetTCPConnection -LocalPort 7777 -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique
  if ($pids) {
    Info "Freeing :7777 (PIDs $($pids -join ', '))"
    foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }
  }
} catch {
  Warn "Could not query/stop processes on :7777: $($_.Exception.Message)"
}
# Ensure package.json exists
$pkgPath = Join-Path $web "package.json"
if (-not (Test-Path $pkgPath)) { Fail "Missing package.json at $pkgPath" }
# Ensure scripts.api exists and dev deps are present
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
$pkg.scripts = $pkg.scripts ?? @{}
if (-not $pkg.scripts.api) { $pkg.scripts.api = "tsx src/server/api.ts" }
# Ensure tsx/types are available; auto-install if missing
$needTsx = -not (Test-Path (Join-Path $web "node_modules/.bin/tsx"))
$needTypes = $false
try {
  $needTypes = -not (Test-Path (Join-Path $web "node_modules/typescript")) -or -not (Test-Path (Join-Path $web "node_modules/@types/node"))
} catch {}
if ($needTsx -or $needTypes) {
  Info "Adding dev deps: tsx, typescript, @types/node"
  Push-Location $web
  pnpm add -D tsx typescript @types/node
  Pop-Location
}
# Persist any script changes
$pkg | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $pkgPath
# Ensure API file exists; scaffold minimal Fastify API if missing
$apiPath = Join-Path $web "src/server/api.ts"
if (-not (Test-Path $apiPath)) {
  New-Item -ItemType Directory -Force (Split-Path $apiPath -Parent) | Out-Null
@"
import Fastify from "fastify";
import "dotenv/config";
const app = Fastify();
app.get("/", async () => ({ ok: true, name: "LGA API" }));
app.post("/run", async (req, res) => {
  const body = (req.body || {}) as { input?: string };
  return { ok: true, echo: body.input ?? "Hello" };
});
app.listen({ port: 7777 }).then(() => console.log("LGA API on :7777"));
"@ | Set-Content -Encoding UTF8 $apiPath
  Info "Scaffolded $apiPath"
}
# Ensure .env exists (template only)
$envPath = Join-Path $web ".env"
if (-not (Test-Path $envPath)) {
@"
# Choose ONE provider:
# OPENAI_API_KEY=PUT_YOUR_KEY_HERE
# OPENAI_MODEL=gpt-4o
# Or local:
# OLLAMA_HOST=http://127.0.0.1:11434
# OLLAMA_MODEL=llama3.1:8b
# Optional RPC
# RPC_HTTP_MAINNET=https://eth.llamarpc.com
"@ | Set-Content -Encoding UTF8 $envPath
  Warn "Created template .env. Add your OpenAI key or OLLAMA settings."
}
# Install deps strictly (uses existing lockfile)
Push-Location $web
pnpm install --frozen-lockfile
if ($NoRun) {
  Info "Checks complete. Skipping API start due to -NoRun."
} else {
  Info "Starting API: pnpm run api"
  pnpm run api
}
Pop-Location
