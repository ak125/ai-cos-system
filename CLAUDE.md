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

**Platform tech stack:** NestJS 10 + Remix 2.15 + React 18 | Supabase (no Prisma) | Redis sessions | Turborepo + npm workspaces | Zod validation | Docker + Caddy | GitHub Actions CI/CD

**RAG tech stack:** Python 3.11 + FastAPI | Weaviate (vector DB) | Claude LLM (Anthropic) | LangGraph orchestration | MinIO + Wiki.js | 352 knowledge docs | Docker Compose multi-service

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
| **nestjs-remix-monorepo** | Core Platform | **TypeScript** — NestJS 10 (40 modules) + Remix 2.15 (158 routes) + React 18. Supabase, Redis, Turborepo, Docker+Caddy. Dev → preprod → **production** (live site) |
| **agent-submissions** | AI Agent Registry | Bundle-based agent submission with signed patches, `constraints.json`, `evidence.json`. Validation against governance rules before deployment |
| **governance-vault** | Governance & Rules | **Obsidian vault** — RULE-H0 to H6 (human authority), R-Vault-01 to 04 (vault rules), R1-R7 (technical rules). 5 automation scripts, ADR/DEC conventions |
| **automecanik-rag** | Knowledge & RAG | **Python 3.11** — FastAPI + Weaviate + Claude LLM + LangGraph. 8,600 lines, 352 knowledge docs, Docker multi-service stack, admin UI, golden tests |

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

## Infrastructure Zones (ADR-012)

4 deployment zones — see [ADR-012](https://github.com/ak125/governance-vault/blob/main/02-decisions/adr/ADR-012-aicos-vps-architecture.md):

| Zone | Server | Role | Access |
|---|---|---|---|
| **local** (DEV) | `46.224.118.55` | Development, Claude Code, local tests | Read/Write |
| **principal_vps** (PROD) | `49.12.233.2` | Production — auto-deploy via `git push main` | Read/Write |
| **aicos_vps** (AI-COS) | `178.104.1.118` | READ-ONLY observatoire — dashboard, health monitoring | READ ONLY |
| **external** | — | External services: Supabase, GitHub, Anthropic API | External |

**AI-COS VPS (`/opt/aicos`):**
- Dashboard React Router 7 — monitoring Supabase, Docker, agents
- MCP configuré : Supabase + GitHub + Filesystem (`/opt/aicos/.mcp.json`, hors git)
- Template sans secrets : `config/mcp.template.json`

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

- All repos follow conventional commits (preferred commit message style)
- **Heterogeneous tech ecosystem:**
  - `nestjs-remix-monorepo` — TypeScript (NestJS + Remix), npm, Turborepo
  - `automecanik-rag` — Python 3.11, FastAPI, pip, Docker Compose
  - `agent-submissions` — Bundle-based (JSON + signed patches)
  - `governance-vault` — Obsidian vault (Markdown documents + shell scripts)
- Each repo has its own CLAUDE.md with repo-specific guidance
- Changes that affect multiple repos should be documented here first
- Shared database: all subsystems connect to Supabase `massdoc` (PostgreSQL)

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
| [docs/rag-deployment.md](docs/rag-deployment.md) | RAG stack deployment, field mapping, safety controls, rollback |
| [docs/roadmap.md](docs/roadmap.md) | Roadmap evolutive Phase 0→4 avec checklist |

## Roadmap Priorities

- [x] Define integration contracts between the 4 subsystems
- [x] Document agent lifecycle (submission -> validation -> deployment)
- [x] Establish governance-to-platform enforcement pipeline
- [x] Study and document all 4 repo architectures (actual tech stacks, structures, capabilities)
- [ ] Set up shared CI/CD pipeline orchestration
- [ ] Create cross-repo automation scripts
- [ ] Implement service health checks
- [x] Connect RAG to live platform — Phase 0 done (feature flag, field mapping, ChatWidget mounted)
- [ ] Build shared types from OpenAPI specs (TypeScript for platform, Python for RAG)

## Notes

- This repository was initialized on 2026-02-07
- Each connected repo maintains its own CLAUDE.md for repo-specific context
- This CLAUDE.md serves as the **global system map** — keep it updated as the ecosystem evolves
