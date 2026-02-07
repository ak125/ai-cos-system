# Governance Enforcement

How governance rules flow from definition to enforcement across the AI-COS ecosystem.

## Enforcement Model

```
  ┌─────────────────────────────────────────────────────────┐
  │                   GOVERNANCE VAULT                       │
  │                                                          │
  │  ┌─────────┐  ┌──────────┐  ┌───────────┐  ┌────────┐  │
  │  │ Policies │  │  Roles   │  │Constraints│  │ Audit  │  │
  │  └────┬─────┘  └────┬─────┘  └─────┬─────┘  └───▲────┘  │
  └───────┼──────────────┼──────────────┼────────────┼───────┘
          │              │              │            │
          ▼              ▼              ▼            │
  ┌─────────────────────────────────────────────────┤───────┐
  │              ENFORCEMENT LAYER                  │       │
  │                                                 │       │
  │  ┌───────────┐  ┌────────────┐  ┌───────────┐  │       │
  │  │  Policy   │  │  Permission│  │ Constraint │  │       │
  │  │  Engine   │  │  Resolver  │  │  Enforcer  │──┘       │
  │  └───────────┘  └────────────┘  └───────────┘          │
  └─────────────────────────────────────────────────────────┘
          │              │              │
          ▼              ▼              ▼
  ┌──────────────┐  ┌──────────┐  ┌──────────────┐
  │   Platform   │  │  Agents  │  │ Orchestrator │
  └──────────────┘  └──────────┘  └──────────────┘
```

## Policy Types

### 1. Constraints
Rules that limit what can be done.

```yaml
example:
  name: "agent-execution-timeout"
  type: constraint
  scope: agents
  rule:
    condition: "agent.executionTime > 120000"
    action: deny
    priority: 100
  rationale: "No agent may run longer than 2 minutes without approval"
```

### 2. Permissions
Rules that grant access.

```yaml
example:
  name: "code-agents-repo-access"
  type: permission
  scope: "capability:code-analysis"
  rule:
    condition: "agent.capabilities includes 'code-analysis'"
    action: allow
    priority: 50
  rationale: "Code analysis agents can read repository contents"
```

### 3. Requirements
Rules that mandate specific behaviors.

```yaml
example:
  name: "mandatory-audit-logging"
  type: requirement
  scope: global
  rule:
    condition: "action.type in ['data-access', 'external-call', 'financial']"
    action: require-approval
    priority: 200
  rationale: "Sensitive actions must be logged with full context"
```

### 4. Prohibitions
Rules that absolutely prevent actions.

```yaml
example:
  name: "no-secret-access"
  type: prohibition
  scope: agents
  rule:
    condition: "resource.type == 'secret' && actor.type == 'agent'"
    action: deny
    priority: 1000
  rationale: "Agents must never directly access secrets"
```

## Enforcement Points

### Pre-execution (Preventive)
Before an action is taken, the platform checks governance:

```
User/Agent request
      │
      ▼
┌─────────────┐     ┌──────────────┐
│  Platform    │────►│  POST        │
│  middleware  │     │  /validate   │
└─────────────┘     └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  Governance   │
                    │  evaluates    │
                    │  all active   │
                    │  policies     │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────▼───┐  ┌────▼────┐  ┌────▼────────┐
         │ Allow  │  │  Deny   │  │  Require     │
         │        │  │         │  │  Approval    │
         └────────┘  └─────────┘  └──────────────┘
```

### Runtime (Detective)
During execution, monitoring detects violations:

- Constraint enforcement (time limits, rate limits, resource limits)
- Anomaly detection (unusual patterns, unexpected resource access)
- Threshold monitoring (approaching limits triggers warnings)

### Post-execution (Corrective)
After actions complete, audit and compliance checks:

- Audit trail completeness verification
- Periodic compliance re-evaluation
- Report generation for human review

## Policy Lifecycle

```
  DRAFT ──► REVIEW ──► ACTIVE ──► REVOKED
              │                      │
              ▼                      ▼
           REJECTED              ARCHIVED
```

| State | Description |
|---|---|
| Draft | Policy written but not yet enforceable |
| Review | Under human review for approval |
| Active | Enforced across all applicable subsystems |
| Revoked | No longer enforced (but kept for audit history) |
| Rejected | Did not pass review |
| Archived | Historical record |

## Conflict Resolution

When multiple policies apply to the same action:

1. **Priority** — Higher priority policies take precedence
2. **Specificity** — More specific scope wins over general scope
3. **Deny wins** — If any applicable policy denies, the action is denied (unless overridden by higher priority allow)
4. **Escalation** — Unresolvable conflicts are escalated to human review

Priority scale:
```
1000+ — Prohibitions (absolute)
500-999 — Security constraints
200-499 — Operational requirements
100-199 — Standard constraints
1-99 — Permissions and allowances
0 — Default (no opinion)
```

## Audit Trail Requirements

Every enforcement action generates an audit entry:

```json
{
  "timestamp": "2026-02-07T17:00:00Z",
  "type": "enforcement",
  "actor": "agent-550e8400",
  "actorType": "agent",
  "action": "invoke-external-api",
  "resource": "https://api.example.com/data",
  "decision": "denied",
  "appliedPolicies": ["no-external-api-without-approval"],
  "reason": "Agent attempted external API call without required approval",
  "severity": "major"
}
```

**Retention policy:**
- All audit entries retained for minimum 1 year
- Critical/security entries retained for 3 years
- Entries are immutable once written

## Human Override

Humans can override governance decisions when necessary:

1. **Emergency override** — Bypasses all policies, requires post-hoc justification
2. **Temporary exemption** — Time-limited policy exception for specific actor/action
3. **Policy amendment** — Modify the policy itself through proper review process

All overrides are:
- Logged with full context
- Time-limited (must be renewed or formalized)
- Visible in compliance reports
- Subject to post-hoc review
