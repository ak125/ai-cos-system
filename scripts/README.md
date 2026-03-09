# Scripts

Cross-repository automation and orchestration scripts for the AI-COS ecosystem.

All scripts run from the `ai-cos-system` root directory and are **READ-ONLY** — safe to run from the AI-COS observatoire VPS (ADR-012).

## Health & Status

| Script | Purpose | Status |
|---|---|---|
| `health-check.sh` | Check all subsystem health endpoints | ✅ Implemented |
| `status-report.sh` | Generate ecosystem-wide status report | ✅ Implemented |

## Development

| Script | Purpose | Status |
|---|---|---|
| `setup-local.sh` | Clone all repos and set up local dev environment | Planned |
| `sync-specs.sh` | Distribute API specs to all subsystems | Planned |
| `validate-contracts.sh` | Verify all repos implement their API contracts correctly | Planned |

## CI/CD

| Script | Purpose | Status |
|---|---|---|
| `cross-repo-test.sh` | Run integration tests across subsystems | Planned |
| `deploy-staging.sh` | Coordinated staging deployment | Planned |
| `deploy-production.sh` | Coordinated production deployment (with approval) | Planned |

## Governance

| Script | Purpose | Status |
|---|---|---|
| `audit-report.sh` | Generate compliance audit report | Planned |
| `policy-sync.sh` | Push policy updates to all subsystems | Planned |

## Usage

Scripts should be run from the `ai-cos-system` root directory:

```sh
./scripts/<script-name>.sh
```

## Usage Examples

### health-check.sh

```sh
# Basic check (colored terminal output)
./scripts/health-check.sh

# JSON output (for CI or piping to jq)
./scripts/health-check.sh --json

# Custom timeout (default: 10s)
./scripts/health-check.sh --timeout 5

# Dry run (no actual HTTP calls)
./scripts/health-check.sh --dry-run

# With environment overrides
PLATFORM_URL=https://automecanik.com \
SUPABASE_ANON_KEY=your_key \
./scripts/health-check.sh --json
```

Exit codes: `0` = all OK/SKIP | `1` = any WARN | `2` = any ERROR

### status-report.sh

```sh
# Markdown report to stdout (default)
./scripts/status-report.sh

# Save Markdown report to file
./scripts/status-report.sh --output /tmp/aicos-status.md

# JSON report (machine-readable)
./scripts/status-report.sh --format json

# Plain text report
./scripts/status-report.sh --format text

# Custom repos directory
REPOS_DIR=/opt/aicos/repos ./scripts/status-report.sh
```

## Environment Variables

| Variable | Used by | Default | Description |
|---|---|---|---|
| `PLATFORM_URL` | health-check | `https://automecanik.com` | NestJS PROD base URL |
| `RAG_SERVICE_URL` | health-check | *(empty — skip)* | RAG FastAPI base URL |
| `WEAVIATE_URL` | health-check | *(empty — skip)* | Weaviate base URL |
| `SUPABASE_URL` | health-check | `https://cxpojprgwgubzjyqzmoq.supabase.co` | Supabase project URL |
| `SUPABASE_ANON_KEY` | health-check | *(empty — skip)* | Supabase anon/service key |
| `GITHUB_ORG` | health-check | `ak125` | GitHub org to check |
| `TIMEOUT` | health-check | `10` | HTTP timeout in seconds |
| `REPOS_DIR` | status-report | `/opt/aicos/repos` | Path to local repo clones |

## Conventions

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`
- Scripts log output with timestamps
- Destructive operations require explicit `--confirm` flag
- All scripts support `--dry-run` for safe testing
- No secrets hardcoded — all credentials via environment variables
- Exit codes follow standard POSIX conventions (0 = success, non-zero = failure)
