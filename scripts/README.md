# Scripts

Cross-repository automation and orchestration scripts for the AI-COS ecosystem.

## Planned Scripts

### Health & Status

| Script | Purpose | Status |
|---|---|---|
| `health-check.sh` | Check all subsystem health endpoints | Planned |
| `status-report.sh` | Generate ecosystem-wide status report | Planned |

### Development

| Script | Purpose | Status |
|---|---|---|
| `setup-local.sh` | Clone all repos and set up local dev environment | Planned |
| `sync-specs.sh` | Distribute API specs to all subsystems | Planned |
| `validate-contracts.sh` | Verify all repos implement their API contracts correctly | Planned |

### CI/CD

| Script | Purpose | Status |
|---|---|---|
| `cross-repo-test.sh` | Run integration tests across subsystems | Planned |
| `deploy-staging.sh` | Coordinated staging deployment | Planned |
| `deploy-production.sh` | Coordinated production deployment (with approval) | Planned |

### Governance

| Script | Purpose | Status |
|---|---|---|
| `audit-report.sh` | Generate compliance audit report | Planned |
| `policy-sync.sh` | Push policy updates to all subsystems | Planned |

## Usage

Scripts should be run from the `ai-cos-system` root directory:

```sh
./scripts/<script-name>.sh
```

## Conventions

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`
- Scripts log output with timestamps
- Destructive operations require explicit `--confirm` flag
- All scripts support `--dry-run` for safe testing
