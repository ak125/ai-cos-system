# AI-COS System Architecture

## 1. Vision

AI-COS (AI Company Operating System) is the foundational infrastructure for running **Automecanik** as an AI-driven company. The system treats AI agents as first-class workers and codifies governance, business logic, and operations into an automated, auditable platform.

**Automecanik** is a **live, production** automotive parts e-commerce platform with:
- **Site in production** — all application code in `nestjs-remix-monorepo` (NestJS + Remix)
- **3.5M+ parts** in catalog, **146M+ vehicle-part compatibility relations**
- **59K+ customers**, **1.6K+ orders**, migrated from a legacy MySQL system
- A sophisticated **SEO engine** (80+ tables, 321K pages, keyword system, quality scoring)
- A **Knowledge Graph** for automotive diagnostics
- An **import pipeline** with staging → normalization → cross-reference layers (CQRS pattern)
- All data hosted on **Supabase** (PostgreSQL) — project `massdoc`

## 2. System Layers

```
┌─────────────────────────────────────────────────────────┐
│                    HUMAN OVERSIGHT                       │
│              Strategic decisions, approvals              │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                 AI-COS ORCHESTRATION                     │
│         ai-cos-system (this repository)                  │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  Contracts   │  │  Config &    │  │  Automation    │  │
│  │  & Specs     │  │  Environment │  │  Scripts       │  │
│  └─────────────┘  └──────────────┘  └────────────────┘  │
└──────────────────────┬──────────────────────────────────┘
                       │
       ┌───────────────┼───────────────┬───────────────┐
       │               │               │               │
┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
│  PLATFORM   │ │   AGENTS    │ │ GOVERNANCE  │ │  KNOWLEDGE  │
│             │ │             │ │             │ │             │
│  nestjs-    │ │  agent-     │ │ governance- │ │ automecanik-│
│  remix-     │ │  submissions│ │ vault       │ │ rag         │
│  monorepo   │ │             │ │             │ │             │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

## 3. Subsystem Responsibilities

### 3.1 ai-cos-system (Orchestrator)

**Role:** Central nervous system — defines how everything connects.

| Concern | Scope |
|---|---|
| Architecture | System-wide design, ADRs, integration patterns |
| Contracts | API specs and shared interfaces between subsystems |
| Configuration | Shared environment variables, feature flags, secrets references |
| Automation | Cross-repo scripts, CI/CD orchestration, deployment coordination |
| Documentation | Global system documentation, onboarding guides |

### 3.2 nestjs-remix-monorepo (Core Platform) — IN PRODUCTION

**Role:** The live Automecanik e-commerce site — everything user-facing and business-critical. This is the **existing, running application** that all other subsystems extend.

**Deployment pipeline:**
```
nestjs-remix-monorepo (dev) ──► preprod ──► prod
```

| Layer | Technology | Purpose |
|---|---|---|
| Backend API | NestJS | REST/GraphQL APIs, business logic, data persistence |
| Frontend | Remix | SSR web application, UI components, user experience |
| Database | Supabase (PostgreSQL) | 200+ tables, 3.5M parts, vehicle catalog, orders |
| Auth | Supabase Auth | Authentication, authorization, role management |
| Queue/Events | TBD | Async processing, event-driven workflows |

**Key data domains served by the platform:**
- Parts catalog (`pieces`, `pieces_criteria`, `pieces_relation_type`)
- Vehicle reference (`auto_marque`, `auto_modele`, `auto_type`)
- E-commerce (`___xtr_customer`, `___xtr_order`, `pieces_price`)
- SEO pages (`__seo_page`, `__seo_keywords`, `__seo_gamme`)
- Read Model / CQRS (`rm_listing`, `rm_product`, `rm_facets`)

### 3.3 agent-submissions (AI Agent Registry)

**Role:** Manage the lifecycle of AI agents that operate within the company.

| Phase | Description |
|---|---|
| Submission | Agent definitions are submitted with metadata, capabilities, and constraints |
| Validation | Agents are tested against governance rules and safety checks |
| Registry | Approved agents are cataloged with versioning |
| Deployment | Agents are activated and assigned to workflows |
| Monitoring | Running agents are tracked, logged, and auditable |

### 3.4 governance-vault (Governance & Compliance)

**Role:** The rule book — defines what the company and its agents can and cannot do.

| Concern | Description |
|---|---|
| Policies | Company-wide rules codified as enforceable specifications |
| Decision Records | Logged decisions with context, rationale, and outcomes |
| Compliance | Regulatory requirements, audit trails, reporting |
| Org Structure | Roles, permissions, hierarchies, delegation rules |
| Agent Constraints | Boundaries and permissions for AI agent behavior |

### 3.5 automecanik-rag (Knowledge & RAG)

**Role:** The knowledge brain — domain-specific Retrieval-Augmented Generation for automotive and mechanical expertise.

| Concern | Description |
|---|---|
| Document Ingestion | Ingest technical manuals, repair guides, parts catalogs, service bulletins |
| Vector Store | Embed and index domain knowledge for semantic retrieval |
| RAG Pipeline | Retrieve relevant context and augment LLM responses with domain knowledge |
| Query API | Expose knowledge search and Q&A endpoints to the platform and agents |
| Knowledge Management | Version, update, and curate the knowledge base over time |

**Existing foundation in Supabase:**
- `__rag_knowledge` — 5 entries (seed data)
- `kg_nodes` (83), `kg_edges` (72) — Knowledge Graph for diagnostic reasoning
- `kg_reasoning_cache`, `kg_safety_triggers` — Diagnostic inference engine
- `__diag_symptoms` (31), `__diag_symptom_family` (35) — Symptom-to-part mapping
- `kg_rag_mapping`, `kg_rag_sync_log` — KG ↔ RAG synchronization

## 4. Data Flow Patterns

### 4.1 Agent Submission Flow

```
Developer/AI submits agent
        │
        ▼
  agent-submissions
  (validate schema)
        │
        ▼
  governance-vault          ◄── checks against policies
  (compliance check)
        │
        ▼
  agent-submissions
  (register & version)
        │
        ▼
  nestjs-remix-monorepo     ◄── deploy to platform
  (activate agent)
```

### 4.2 Governance Enforcement Flow

```
  governance-vault
  (policy updated)
        │
        ▼
  ai-cos-system             ◄── propagate change
  (orchestration)
        │
        ├──► agent-submissions    (re-validate active agents)
        │
        └──► nestjs-remix-monorepo (update platform rules)
```

### 4.3 Platform Request Flow

```
  User/Client request
        │
        ▼
  nestjs-remix-monorepo
  (handle request)
        │
        ├──► agent-submissions    (invoke AI agent if needed)
        ├──► governance-vault     (check permissions/rules)
        └──► automecanik-rag     (query domain knowledge)
```

### 4.4 Knowledge Query Flow

```
  User asks automotive question
        │
        ▼
  nestjs-remix-monorepo
  (receive query)
        │
        ▼
  automecanik-rag              ◄── semantic search in vector store
  (retrieve + augment)
        │
        ▼
  AI Agent (if needed)         ◄── agent uses RAG context for response
  (generate answer)
        │
        ▼
  nestjs-remix-monorepo
  (return to user)
```

## 5. Communication Patterns

| Pattern | Use Case | Implementation |
|---|---|---|
| **Sync API** | Real-time queries (auth checks, agent lookup) | REST/GraphQL between services |
| **Events/Webhooks** | Policy changes, agent status updates | Event bus or webhook notifications |
| **Shared Contracts** | API compatibility | OpenAPI/JSON Schema specs in `ai-cos-system/specs/` |
| **Config Sync** | Shared environment & feature flags | Centralized config in `ai-cos-system/config/` |

## 6. Security Model

```
┌────────────────────────────────────┐
│         Security Boundaries        │
│                                    │
│  ┌──────────┐    ┌──────────────┐  │
│  │ Platform  │◄──│  Auth/RBAC   │  │
│  │ (public)  │   │  (internal)  │  │
│  └──────────┘    └──────────────┘  │
│                                    │
│  ┌──────────┐    ┌──────────────┐  │
│  │  Agents   │◄──│  Governance  │  │
│  │ (scoped)  │   │  (enforced)  │  │
│  └──────────┘    └──────────────┘  │
└────────────────────────────────────┘
```

- **Platform access**: Standard auth (JWT/sessions), RBAC for humans
- **Agent access**: Scoped permissions defined in governance-vault, enforced per-agent
- **Cross-service**: Signed requests, service-to-service auth tokens
- **Secrets**: Never in repos — referenced via environment config, stored in vault

## 7. Technology Stack Summary

| Layer | Technology | Status |
|---|---|---|
| Backend Framework | NestJS | Active |
| Frontend Framework | Remix | Active |
| Language | TypeScript | Active |
| Database | **Supabase (PostgreSQL)** | **Active** — project `massdoc`, 200+ tables |
| Database Hosting | **Supabase Pro** (ak125's Org) | **Active** |
| Vector Database | **pgvector** (via Supabase) | Available — native PostgreSQL extension |
| Knowledge Graph | **PostgreSQL** (kg_* tables) | **Active** — 83 nodes, 72 edges |
| RAG Foundation | **PostgreSQL** (__rag_knowledge, kg_rag_*) | **Seeded** — 5 entries |
| Package Manager | TBD (npm/pnpm/yarn) | To decide |
| Cache | TBD | To decide |
| Message Queue | TBD | To decide |
| CI/CD | TBD (GitHub Actions likely) | To decide |
| Hosting | TBD | To decide |
| Embeddings | TBD (OpenAI/Cohere/local) | To decide |
| Monitoring | TBD | To decide |

## 8. Scaling Strategy

**Phase 1 — Foundation — DONE**
- [x] Build core platform (NestJS + Remix) — **IN PRODUCTION** on `nestjs-remix-monorepo`
- [x] Migrate MySQL → PostgreSQL (Supabase) — **DONE** (200+ tables migrated)
- [x] Build catalog/SEO data layer — **DONE** (3.5M parts, 321K SEO pages)
- [x] Build import pipeline (stg → norm → xref) — **DONE** (CQRS pattern)
- [x] Build Knowledge Graph — **DONE** (83 nodes, 72 edges, diagnostic engine)
- [x] Build diagnostic symptom system — **DONE** (31 symptoms, 35 families)
- [x] Establish repo structure and contracts — **DONE**

**Phase 2 — AI Augmentation (current)**
- [ ] Scale RAG from 5 entries to full knowledge base (blog content, repair guides, KG data)
- [ ] Integrate diagnostic engine with RAG pipeline
- [ ] Define governance framework — on `governance-vault`
- [ ] Set up first AI agents — on `agent-submissions`
- [ ] Connect subsystems to the live platform via defined contracts

**Phase 3 — Full AI Operations**
- Multi-agent orchestration
- Automated governance enforcement
- Event-driven communication across all subsystems
- CI/CD across all repos
- Real-time monitoring and observability
- SEO generation fully AI-driven
- Auto-scaling infrastructure
