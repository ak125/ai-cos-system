# ADR-002: AI-Driven Company Operating Model

**Date:** 2026-02-07
**Status:** Accepted
**Deciders:** Founder

## Context

This company is designed from the ground up to be operated primarily by AI agents, with human oversight for strategic decisions. We need to define the operating model that governs how AI and humans collaborate.

## Decision

Adopt an **AI-first, human-governed** operating model:

### Operating Principles

1. **AI agents are workers** — They execute tasks, make operational decisions, and handle routine work
2. **Humans are governors** — They set strategy, define policies, approve critical decisions, and provide oversight
3. **Governance as code** — All rules, constraints, and policies are codified and version-controlled
4. **Everything is auditable** — Every action by every agent is logged with full context
5. **Least privilege** — Agents only have the permissions explicitly granted by governance

### Decision Authority Matrix

| Decision Type | Authority | Approval Required |
|---|---|---|
| Routine operations | AI Agent | None (within policy) |
| New agent deployment | AI Agent | Governance validation |
| Policy changes | Human | Human approval |
| Strategic direction | Human | Founder approval |
| Emergency actions | AI Agent | Post-hoc human review |
| Financial transactions | AI Agent | Human approval above threshold |
| Code deployment | AI Agent | CI/CD checks + governance rules |
| Data access | AI Agent | Policy-defined scope |

### Agent Hierarchy

```
Founder (Human)
    │
    ├── Strategic AI Advisor (Agent)
    │       └── Suggests strategy, human decides
    │
    ├── Operations Manager (Agent)
    │       ├── Task execution agents
    │       ├── Communication agents
    │       └── Reporting agents
    │
    ├── Development Lead (Agent)
    │       ├── Code generation agents
    │       ├── Review agents
    │       └── Testing agents
    │
    └── Compliance Officer (Agent)
            ├── Policy enforcement agents
            ├── Audit agents
            └── Risk assessment agents
```

## Rationale

- **Scalability**: AI agents can operate 24/7 without fatigue
- **Consistency**: Codified governance ensures rules are always followed
- **Auditability**: Full transparency on every action and decision
- **Agility**: New agents can be deployed quickly for new capabilities
- **Safety**: Human oversight on critical decisions prevents uncontrolled AI action

## Consequences

- Need robust agent submission and validation pipeline
- Governance framework must be comprehensive before agents go live
- Audit logging is a hard requirement for every subsystem
- Human review workflows must be well-designed (not a bottleneck)
- Must define clear escalation paths when agents encounter edge cases

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Agent makes harmful decision | Governance constraints + audit trail + rollback capability |
| Governance rules too rigid | Regular human review of policies, feedback loop from agents |
| Single point of failure (founder) | Document decision framework, delegate progressively |
| Compliance gaps | Regular audits, automated compliance checking |
