# EIC Light Grid
[![web-ci](https://github.com/eickommanderaeon/eic-light-grid/actions/workflows/web-ci.yml/badge.svg)](https://github.com/eickommanderaeon/eic-light-grid/actions/workflows/web-ci.yml)


Public trunk for the Energy Intelligence Coin (EIC) ecosystem:
- **contracts/** — on-chain components (token, treasury, interfaces)
- **web/** — Next.js DApp (no secrets)
- **docs/** — public docs (Litepaper, API)
- **scripts/** — deploy/verify templates (keyless)

> Security model: No secrets or live CSVs are ever committed. Use env vars and GitHub Actions Secrets.

## Architecture
- **Contracts**: Foundry (Solc 0.8.x), OZ libraries where applicable.
- **Frontend**: Next.js App Router + RainbowKit/Viem.
- **CI**: Foundry build/test; pnpm build for web.

## Getting Started
```bash
# Contracts
cd contracts
forge fmt && forge build && forge test

# Web
cd ../web
cp .env.example .env.local
pnpm install
pnpm dev
```

Directories
contracts/    # EIC token, treasury, interfaces
web/          # DApp (no secrets)
docs/         # LITEPAPER.md, API.md
scripts/      # deploy/verify templates
.github/      # CI workflows

Contributing

PRs welcome via forks. All PRs require passing CI.

Security

See SECURITY.md for responsible disclosure. Do not open issues for vulnerabilities.

License

Apache-2.0
