# Integration Map

How the AI-COS subsystems communicate and depend on each other.

## Dependency Matrix

| From ↓ / To → | ai-cos-system | nestjs-remix-monorepo | agent-submissions | governance-vault |
|---|---|---|---|---|
| **ai-cos-system** | — | Provides contracts & config | Provides contracts & config | Provides contracts & config |
| **nestjs-remix-monorepo** | Reads specs | — | Invokes agents, reads registry | Checks policies, reads rules |
| **agent-submissions** | Reads specs | Deploys agents to platform | — | Validates against policies |
| **governance-vault** | Reads specs | Pushes rule updates | Pushes constraint updates | — |

## Integration Points

### 1. Platform ↔ Agent Registry

**Purpose:** The platform needs to discover, invoke, and manage AI agents.

```
nestjs-remix-monorepo          agent-submissions
       │                              │
       │── GET /agents/available ─────►│  List available agents
       │── POST /agents/:id/invoke ──►│  Trigger an agent
       │◄── webhook /agent-status ────│  Agent execution result
       │── GET /agents/:id/logs ─────►│  Agent audit trail
```

**Contract:** `specs/platform-agents.yaml`

### 2. Platform ↔ Governance

**Purpose:** The platform checks governance rules before executing actions.

```
nestjs-remix-monorepo          governance-vault
       │                              │
       │── GET /policies/active ─────►│  Current active policies
       │── POST /validate ───────────►│  Validate action against rules
       │◄── webhook /policy-update ──│  Policy changed notification
       │── GET /roles/:id ───────────►│  Role & permission lookup
```

**Contract:** `specs/platform-governance.yaml`

### 3. Agent Registry ↔ Governance

**Purpose:** Agents must comply with governance rules at all times.

```
agent-submissions              governance-vault
       │                              │
       │── POST /validate-agent ─────►│  Check agent against policies
       │◄── webhook /policy-update ──│  Re-validate on policy change
       │── GET /constraints ─────────►│  Fetch agent constraints
       │── POST /audit-log ──────────►│  Report agent actions
```

**Contract:** `specs/agents-governance.yaml`

### 4. Orchestrator → All Subsystems

**Purpose:** ai-cos-system coordinates cross-cutting concerns.

```
ai-cos-system
       │
       ├── Publishes shared config ──► all repos read from config/
       ├── Defines API contracts ────► all repos implement specs/
       ├── Runs health checks ───────► all subsystems report status
       └── Triggers cross-repo CI ──► coordinated deployments
```

## Event Catalog

| Event | Producer | Consumers | Description |
|---|---|---|---|
| `agent.submitted` | agent-submissions | governance-vault | New agent needs validation |
| `agent.validated` | governance-vault | agent-submissions | Agent passed compliance |
| `agent.rejected` | governance-vault | agent-submissions | Agent failed compliance |
| `agent.deployed` | agent-submissions | nestjs-remix-monorepo | Agent ready for use |
| `agent.invoked` | nestjs-remix-monorepo | agent-submissions | Agent was called |
| `agent.completed` | agent-submissions | nestjs-remix-monorepo | Agent finished execution |
| `policy.created` | governance-vault | ai-cos-system | New policy added |
| `policy.updated` | governance-vault | all | Policy changed |
| `policy.revoked` | governance-vault | all | Policy removed |
| `platform.action` | nestjs-remix-monorepo | governance-vault | Action for audit |

## Shared Data Schemas

All subsystems agree on these core entity shapes (defined in `specs/schemas/`):

### Agent

```json
{
  "id": "string (uuid)",
  "name": "string",
  "version": "string (semver)",
  "status": "submitted | validating | approved | rejected | deployed | suspended",
  "capabilities": ["string"],
  "constraints": {
    "maxExecutionTime": "number (ms)",
    "allowedActions": ["string"],
    "requiredApprovals": "number"
  },
  "metadata": {
    "author": "string",
    "createdAt": "ISO 8601",
    "updatedAt": "ISO 8601"
  }
}
```

### Policy

```json
{
  "id": "string (uuid)",
  "name": "string",
  "type": "constraint | permission | requirement | prohibition",
  "scope": "global | agents | platform | specific-agent-id",
  "rule": {
    "condition": "string (expression)",
    "action": "allow | deny | require-approval",
    "priority": "number"
  },
  "status": "draft | active | revoked",
  "metadata": {
    "author": "string",
    "rationale": "string",
    "createdAt": "ISO 8601",
    "effectiveDate": "ISO 8601"
  }
}
```

### AuditEntry

```json
{
  "id": "string (uuid)",
  "timestamp": "ISO 8601",
  "actor": "string (user-id or agent-id)",
  "actorType": "human | agent | system",
  "action": "string",
  "resource": "string",
  "outcome": "success | failure | denied",
  "policyRef": "string (policy-id, if applicable)",
  "details": "object"
}
```

## Environment Strategy

| Environment | Purpose | Deployment |
|---|---|---|
| `development` | Local dev, feature branches | Local / Docker Compose |
| `staging` | Integration testing, pre-release | Cloud (single instance) |
| `production` | Live system | Cloud (scaled) |

Each subsystem maintains its own deployment but shares:
- Database connection patterns (defined in `config/`)
- API base URLs per environment (defined in `config/`)
- Feature flags (defined in `config/`)
