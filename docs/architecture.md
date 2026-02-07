# AI-COS System Architecture

## 1. Vision

AI-COS (AI Company Operating System) is the foundational infrastructure for running an AI-driven company. The system treats AI agents as first-class workers and codifies governance, business logic, and operations into an automated, auditable platform.

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
       ┌───────────────┼───────────────┐
       │               │               │
┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
│  PLATFORM   │ │   AGENTS    │ │ GOVERNANCE  │
│             │ │             │ │             │
│  nestjs-    │ │  agent-     │ │ governance- │
│  remix-     │ │  submissions│ │ vault       │
│  monorepo   │ │             │ │             │
└─────────────┘ └─────────────┘ └─────────────┘
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

### 3.2 nestjs-remix-monorepo (Core Platform)

**Role:** The product — everything user-facing and business-critical.

| Layer | Technology | Purpose |
|---|---|---|
| Backend API | NestJS | REST/GraphQL APIs, business logic, data persistence |
| Frontend | Remix | SSR web application, UI components, user experience |
| Database | TBD | Data storage, migrations, seeding |
| Auth | TBD | Authentication, authorization, role management |
| Queue/Events | TBD | Async processing, event-driven workflows |

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
        │
        └──► governance-vault     (check permissions/rules)
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
| Package Manager | TBD (npm/pnpm/yarn) | To decide |
| Database | TBD | To decide |
| Cache | TBD | To decide |
| Message Queue | TBD | To decide |
| CI/CD | TBD (GitHub Actions likely) | To decide |
| Hosting | TBD | To decide |
| Monitoring | TBD | To decide |

## 8. Scaling Strategy

**Phase 1 — Foundation (current)**
- Establish repo structure and contracts
- Build core platform (NestJS + Remix)
- Define governance framework
- Set up first AI agents

**Phase 2 — Integration**
- Connect all 3 subsystems via defined contracts
- Implement event-driven communication
- Automated governance enforcement
- CI/CD across all repos

**Phase 3 — Scale**
- Multi-agent orchestration
- Real-time monitoring and observability
- Auto-scaling infrastructure
- Advanced compliance and audit tooling
