Param([switch]$NoRun)
$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Warning $m }
function Fail($m){ throw $m }

# Versions
Info "Node: $(node -v)"
if (Get-Command pnpm -ErrorAction SilentlyContinue) { Info "pnpm: $(pnpm -v)" } else { Fail "pnpm not found. Install: https://pnpm.io/installation" }

# FFmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Warn "ffmpeg not found; installing via winget…
"
    try { winget install --id=Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements | Out-Null } catch {}
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
      try { winget install --id=FFmpeg.FFmpeg -e --accept-source-agreements --accept-package-agreements | Out-Null } catch {}
    }
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { Warn "ffmpeg may need a NEW PowerShell window, or install via: choco install ffmpeg" }
    else { Info "ffmpeg installed." }
  } else {
    Warn "winget not found. Install ffmpeg manually or via: choco install ffmpeg"
  }
} else { Info "ffmpeg found." }

# Free :7777 (handle multiple PIDs)
$pids = (Get-NetTCPConnection -LocalPort 7777 -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique
if ($pids) { Info "Freeing :7777 (PIDs $($pids -join ', '))"; foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } }

# Ensure package.json exists
$pkgPath = Join-Path (Get-Location) "package.json"
if (-not (Test-Path $pkgPath)) { Fail "Missing package.json at $pkgPath" }

# Ensure scripts.api exists + dev deps
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
$pkg.scripts = $pkg.scripts ?? @{}
if (-not $pkg.scripts.api) { $pkg.scripts.api = "tsx src/server/api.ts" }
$needTsx = -not (Test-Path ".\node_modules\.bin\tsx")
$needTypes = -not (Test-Path ".\node_modules\typescript") -or -not (Test-Path ".\node_modules\@types\node")
if ($needTsx -or $needTypes) { Info "Adding dev deps: tsx typescript @types/node"; pnpm add -D tsx typescript @types/node }

# Persist any script changes
$pkg | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $pkgPath

# Ensure minimal API file
$apiPath = ".\src\server\api.ts"
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

# Ensure .env (template only)
if (-not (Test-Path ".\.env")) {
@"
# Choose ONE provider:
# OPENAI_API_KEY=PUT_YOUR_KEY_HERE
# OPENAI_MODEL=gpt-4o
# Or local:
# OLLAMA_HOST=http://127.0.0.1:11434
# OLLAMA_MODEL=llama3.1:8b

# Optional RPC
# RPC_HTTP_MAINNET=https://eth.llamarpc.com
"@ | Set-Content -Encoding UTF8 ".\.env"
  Warn "Created template .env. Add your OpenAI key or OLLAMA settings."
}

# Strict install (uses committed lockfile)
pnpm install --frozen-lockfile

if ($NoRun) { Info "Checks complete. Skipping API start (NoRun)."; exit 0 }
Info "Starting API: pnpm run api"
pnpm run api
