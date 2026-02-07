# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

**ai-cos-system** (AI Company Operating System) is the central orchestration layer for **Automecanik**, an **AI-driven automotive parts e-commerce company**. It coordinates and connects all subsystems that power the organization's operations, governance, and development infrastructure.

This is not a standalone application — it is the **umbrella system** that ties together the company's core repositories and ensures they work as a unified platform.

## Business Context

**Automecanik** is a **live, production** automotive parts e-commerce platform:
- **Site in production** — all code lives in `nestjs-remix-monorepo`
- **3.5M+ parts** in catalog across 992 brands
- **146M+ vehicle-part compatibility** relations
- **48,918 vehicle motorizations** across 117 brands and 5,745 models
- **59K+ customers**, **1.6K+ orders**
- **321K SEO pages** with a sophisticated 80+ table SEO engine
- **Knowledge Graph** (83 nodes, 72 edges) for automotive diagnostics
- **Data hosted on Supabase** (PostgreSQL) — project `massdoc`, ~100 GB
- **Migrated from legacy MySQL** to PostgreSQL with full data pipeline

**Tech stack (production):** NestJS 10 + Remix 2.15 + React 18 | Supabase (no Prisma) | Redis sessions | Turborepo + npm workspaces | Zod validation | Docker + Caddy | GitHub Actions CI/CD

## Ecosystem Architecture

```
ai-cos-system/                          # Central orchestration & system design
│
├── CLAUDE.md                           # This file — global context for Claude Code
├── .gitignore                          # Git ignore rules
│
├── docs/                               # System-wide documentation
│   ├── architecture.md                 # System layers, subsystem roles, scaling strategy
│   ├── integration-map.md              # Dependency matrix, events, shared schemas
│   ├── agent-lifecycle.md              # Agent stages: submit → validate → deploy → operate
│   ├── governance-enforcement.md       # Policy types, enforcement points, audit trail
│   ├── database-architecture.md       # Supabase/PostgreSQL schema (200+ tables)
│   └── decisions/                      # Architecture Decision Records
│       ├── ADR-001-multi-repo-architecture.md
│       └── ADR-002-ai-driven-company-model.md
│
├── specs/                              # OpenAPI contracts between subsystems
│   ├── platform-agents.yaml            # nestjs-remix ↔ agent-submissions
│   ├── platform-governance.yaml        # nestjs-remix ↔ governance-vault
│   ├── agents-governance.yaml          # agent-submissions ↔ governance-vault
│   └── platform-rag.yaml              # nestjs-remix ↔ automecanik-rag
│
├── config/                             # Shared configuration & environment
│   └── README.md                       # Config structure & conventions
│
└── scripts/                            # Cross-project automation
    └── README.md                       # Script catalog & conventions
```

## Connected Repositories

| Repository | Role | Description |
|---|---|---|
| **nestjs-remix-monorepo** | Core Platform | NestJS backend + Remix frontend. Development repo → **preprod** → **production** (live Automecanik site) |
| **agent-submissions** | AI Agent Registry | Manages AI agent definitions, submissions, validation, and deployment workflows |
| **governance-vault** | Governance & Rules | Company governance framework — policies, decision records, compliance rules, and organizational structure |
| **automecanik-rag** | Knowledge & RAG | Retrieval-Augmented Generation system for automotive/mechanical domain knowledge |

### How they connect

```
                       ┌─────────────────────┐
                       │   ai-cos-system     │
                       │  (orchestration &   │
                       │   system design)    │
                       └────────┬────────────┘
                                │
       ┌────────────┬───────────┼───────────┬────────────┐
       │            │           │           │            │
┌──────▼───┐ ┌──────▼──────┐ ┌─▼──────────┐ ┌──────▼───────┐
│ nestjs-  │ │   agent-    │ │ governance-│ │ automecanik- │
│ remix-   │ │ submissions │ │ vault      │ │ rag          │
│ monorepo │ │             │ │            │ │              │
│ LIVE     │ │ AI agents   │ │ Policies/  │ │ Knowledge/   │
│ PROD     │ │ registry &  │ │ Rules/     │ │ RAG/         │
│ SITE     │ │ workflows   │ │ Compliance │ │ Automotive   │
└──────────┘ └─────────────┘ └────────────┘ └──────────────┘
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
| 2026-02-07 | Supabase as database platform | PostgreSQL on Supabase Pro (project massdoc), migrated from legacy MySQL |
| 2026-02-07 | Add automecanik-rag as 4th subsystem | RAG + Knowledge Graph for automotive domain knowledge and diagnostics |

## Key Documentation

| Document | What it covers |
|---|---|
| [docs/architecture.md](docs/architecture.md) | System layers, subsystem roles, tech stack, scaling phases |
| [docs/database-architecture.md](docs/database-architecture.md) | Supabase schema: 200+ tables, data domains, naming conventions |
| [docs/integration-map.md](docs/integration-map.md) | Dependency matrix, API flows, event catalog, shared schemas |
| [docs/agent-lifecycle.md](docs/agent-lifecycle.md) | Full agent journey: submit → validate → register → deploy → monitor |
| [docs/governance-enforcement.md](docs/governance-enforcement.md) | Policy types, enforcement model, conflict resolution, audit trail |
| [docs/decisions/ADR-001](docs/decisions/ADR-001-multi-repo-architecture.md) | Why multi-repo with orchestrator |
| [docs/decisions/ADR-002](docs/decisions/ADR-002-ai-driven-company-model.md) | AI-first, human-governed operating model |

## Roadmap Priorities

- [x] Define integration contracts between the 4 subsystems
- [x] Document agent lifecycle (submission -> validation -> deployment)
- [x] Establish governance-to-platform enforcement pipeline
- [ ] Set up shared CI/CD pipeline orchestration
- [ ] Create cross-repo automation scripts
- [ ] Implement service health checks
- [ ] Build shared TypeScript types package from OpenAPI specs

## Notes

- This repository was initialized on 2026-02-07
- Each connected repo maintains its own CLAUDE.md for repo-specific context
- This CLAUDE.md serves as the **global system map** — keep it updated as the ecosystem evolves
