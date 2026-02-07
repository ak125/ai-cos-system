# Config

Shared configuration for the AI-COS ecosystem.

## Structure

```
config/
├── README.md                  # This file
├── environments/
│   ├── development.yaml       # Local development settings
│   ├── staging.yaml           # Staging environment
│   └── production.yaml        # Production environment
├── feature-flags.yaml         # Feature flags shared across subsystems
└── services.yaml              # Service registry (URLs, ports, health endpoints)
```

## Principles

1. **No secrets in config** — Use references to secret managers, never plaintext
2. **Environment parity** — All environments share the same structure, only values differ
3. **Version controlled** — All config changes go through PR review
4. **Subsystem consumption** — Each repo reads its relevant config section at startup

## Service Registry Format

```yaml
services:
  platform:
    repo: nestjs-remix-monorepo
    endpoints:
      api: "${PLATFORM_API_URL}"
      web: "${PLATFORM_WEB_URL}"
      health: "${PLATFORM_API_URL}/health"

  agent-registry:
    repo: agent-submissions
    endpoints:
      api: "${AGENT_REGISTRY_URL}"
      health: "${AGENT_REGISTRY_URL}/health"

  governance:
    repo: governance-vault
    endpoints:
      api: "${GOVERNANCE_API_URL}"
      health: "${GOVERNANCE_API_URL}/health"
```
