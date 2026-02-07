# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

**ai-cos-system** (AI Company Operating System) is the central orchestration layer for an **AI-driven company**. It coordinates and connects all subsystems that power the organization's operations, governance, and development infrastructure.

This is not a standalone application — it is the **umbrella system** that ties together the company's core repositories and ensures they work as a unified platform.

## Ecosystem Architecture

```
ai-cos-system/                          # Central orchestration & system design
│
├── CLAUDE.md                           # This file — global context for Claude Code
├── docs/                               # System-wide documentation & architecture
│   ├── architecture.md                 # Overall system design
│   ├── integration-map.md              # How subsystems connect
│   └── decisions/                      # ADRs (Architecture Decision Records)
│
├── config/                             # Shared configuration & environment
├── scripts/                            # Cross-project automation & orchestration
└── specs/                              # API contracts & shared interfaces
```

## Connected Repositories

| Repository | Role | Description |
|---|---|---|
| **nestjs-remix-monorepo** | Core Platform | Main tech stack — NestJS backend + Remix frontend. Handles product, APIs, UI, and business logic |
| **agent-submissions** | AI Agent Registry | Manages AI agent definitions, submissions, validation, and deployment workflows |
| **governance-vault** | Governance & Rules | Company governance framework — policies, decision records, compliance rules, and organizational structure |

### How they connect

```
                    ┌─────────────────────┐
                    │   ai-cos-system     │
                    │  (orchestration &   │
                    │   system design)    │
                    └────────┬────────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
   ┌────────▼──────┐  ┌─────▼──────┐  ┌──────▼───────┐
   │  nestjs-remix  │  │   agent-   │  │  governance- │
   │   monorepo     │  │submissions │  │    vault     │
   │                │  │            │  │              │
   │ Product/APIs/  │  │ AI agents  │  │  Policies/   │
   │ UI/Business    │  │ registry & │  │  Rules/      │
   │ logic          │  │ workflows  │  │  Compliance  │
   └────────────────┘  └────────────┘  └──────────────┘
```

## AI-Driven Company Principles

This organization operates as an AI-native company. Key principles:

1. **AI-first workflows** — AI agents handle operations, with human oversight for strategic decisions
2. **Governance as code** — Company rules and policies are codified, versioned, and enforceable
3. **Agent orchestration** — AI agents are submitted, validated, and deployed through structured pipelines
4. **Unified system** — All subsystems share contracts, configurations, and communication standards
5. **Transparency** — All decisions, changes, and agent actions are logged and auditable

## Development Guidelines

### For this repository (ai-cos-system)

This repo contains:
- System-wide architecture documentation
- Cross-project integration specs and API contracts
- Shared configuration and environment definitions
- Orchestration scripts and automation
- Architecture Decision Records (ADRs)

### Cross-repo conventions

- All repos follow the same commit message style (conventional commits preferred)
- Shared TypeScript/Node.js ecosystem (NestJS + Remix stack)
- Each repo has its own CLAUDE.md with repo-specific guidance
- Changes that affect multiple repos should be documented here first

### Branching strategy

- `main` — stable, production-ready state
- `claude/*` — AI-assisted development branches
- Feature branches follow `feature/<description>` convention

## Key Decisions Log

Track major architectural and organizational decisions here:

| Date | Decision | Context |
|---|---|---|
| 2026-02-07 | Adopt multi-repo structure with ai-cos-system as orchestrator | Separation of concerns between platform, agents, and governance |
| 2026-02-07 | AI-driven company model | Organization operates with AI agents as primary workers, humans as strategic oversight |

## Roadmap Priorities

- [ ] Define integration contracts between the 3 subsystems
- [ ] Set up shared CI/CD pipeline orchestration
- [ ] Document agent lifecycle (submission -> validation -> deployment)
- [ ] Establish governance-to-platform enforcement pipeline
- [ ] Create cross-repo automation scripts

## Notes

- This repository was initialized on 2026-02-07
- Each connected repo maintains its own CLAUDE.md for repo-specific context
- This CLAUDE.md serves as the **global system map** — keep it updated as the ecosystem evolves
