# Agent Lifecycle

Complete lifecycle of an AI agent within the AI-COS ecosystem, from creation to retirement.

## Lifecycle Stages

```
  ┌──────────┐    ┌────────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
  │  SUBMIT  │───►│  VALIDATE  │───►│ REGISTER │───►│  DEPLOY  │───►│ OPERATE  │
  └──────────┘    └────────────┘    └──────────┘    └──────────┘    └──────────┘
                        │                                                 │
                        │ fail                                       ┌────▼────┐
                        ▼                                            │ MONITOR │
                  ┌──────────┐                                       └────┬────┘
                  │ REJECTED │                                            │
                  └──────────┘                                  ┌─────────┼─────────┐
                                                                │         │         │
                                                           ┌────▼──┐ ┌───▼───┐ ┌───▼────┐
                                                           │SUSPEND│ │UPDATE │ │ RETIRE │
                                                           └───────┘ └───────┘ └────────┘
```

## Stage Details

### 1. Submit

**Repo:** agent-submissions
**Actor:** Developer or AI agent

An agent is submitted with:

| Field | Required | Description |
|---|---|---|
| name | Yes | Unique agent identifier |
| version | Yes | Semver version string |
| description | Yes | What the agent does |
| capabilities | Yes | List of capabilities (e.g., "code-generation", "data-analysis") |
| requestedPermissions | Yes | What the agent needs access to |
| entrypoint | Yes | How to invoke the agent |
| author | Yes | Who created the agent |
| testResults | Recommended | Evidence the agent works correctly |

**Validation at this stage:** Schema validation only — is the submission well-formed?

### 2. Validate

**Repo:** governance-vault (via agents-governance API)
**Actor:** Automated governance checks

The governance system evaluates:

1. **Policy compliance** — Does the agent violate any active policies?
2. **Permission check** — Are requested permissions acceptable?
3. **Capability review** — Are the claimed capabilities within allowed scope?
4. **Safety assessment** — Does the agent pose any identified risks?
5. **Conflict detection** — Does this agent conflict with existing agents?

**Outcomes:**
- `approved` — Agent passes all checks
- `rejected` — Agent violates one or more policies (with reasons)
- `conditional` — Agent can proceed with additional constraints applied

### 3. Register

**Repo:** agent-submissions
**Actor:** Automated after validation

Once approved:
- Agent is added to the registry with a unique ID
- Version is recorded (supports multiple versions)
- Status set to `approved`
- Constraints from governance are attached to the agent record

### 4. Deploy

**Repo:** agent-submissions → nestjs-remix-monorepo
**Actor:** Automated or human-triggered

Deployment involves:
1. Agent becomes available in the platform's agent catalog
2. Platform is notified via `agent.deployed` event
3. Agent constraints are enforced by the platform runtime
4. Health check confirms the agent is operational

### 5. Operate

**Repo:** nestjs-remix-monorepo (execution) + agent-submissions (tracking)
**Actor:** AI agent (triggered by platform or other agents)

During operation:
- Platform invokes agent via `/agents/{id}/invoke`
- Agent executes within its constraint boundaries
- Every action is logged to governance audit trail
- Results are returned to the caller

### 6. Monitor

**Repo:** ai-cos-system (orchestration) + all subsystems
**Actor:** Automated monitoring

Continuous monitoring checks:
- Execution frequency and patterns
- Error rates and failure modes
- Resource consumption
- Policy compliance (ongoing)
- Performance against SLAs

### 7. Suspend

**Trigger:** Policy violation, anomaly detected, or human decision

When suspended:
- Agent status changes to `suspended`
- Platform stops accepting invocations for this agent
- Active executions are allowed to complete (with timeout)
- Audit entry is created with suspension reason
- Human review may be required before reactivation

### 8. Update

**Trigger:** New version submitted

Update flow:
1. New version submitted (back to Submit stage)
2. Previous version continues operating during validation
3. On approval, traffic shifts to new version
4. Old version is deprecated (kept for rollback)
5. Rollback window expires → old version archived

### 9. Retire

**Trigger:** Agent no longer needed, or permanently non-compliant

Retirement process:
1. Agent status set to `retired`
2. Platform removes from available agents
3. Running instances complete or are terminated
4. Logs and audit trail are preserved
5. Agent definition is archived (not deleted)

## State Machine

```
submitted ──► validating ──► approved ──► deployed ──► active
                  │                                      │
                  ▼                                      ├──► suspended ──► active (reactivated)
               rejected                                  │                     │
                                                         ├──► updating ───────►│
                                                         │
                                                         └──► retired
```

## Events Emitted Per Stage

| Stage | Event | Consumer |
|---|---|---|
| Submit | `agent.submitted` | governance-vault |
| Validate (pass) | `agent.validated` | agent-submissions |
| Validate (fail) | `agent.rejected` | agent-submissions |
| Register | `agent.registered` | ai-cos-system |
| Deploy | `agent.deployed` | nestjs-remix-monorepo |
| Invoke | `agent.invoked` | agent-submissions |
| Complete | `agent.completed` | nestjs-remix-monorepo |
| Suspend | `agent.suspended` | all |
| Retire | `agent.retired` | all |

## Example: Deploying a Code Review Agent

```
1. Developer submits "code-review-agent" v1.0.0
   - capabilities: ["code-analysis", "pr-review"]
   - permissions: ["read:repositories", "write:pr-comments"]

2. Governance validates:
   ✓ No policy violations
   ✓ Permissions are within allowed scope
   ✓ No conflicts with existing agents
   → Decision: approved

3. Agent registered in registry
   - ID: 550e8400-e29b-41d4-a716-446655440000
   - Constraints: max 60s execution, no access to secrets

4. Agent deployed to platform
   - Available at /agents/550e.../invoke
   - Health check: passing

5. Platform invokes on new PR:
   - POST /agents/550e.../invoke { task: "review PR #42" }
   - Agent analyzes code, posts review comments
   - Audit log: action=pr-review, outcome=success, duration=12s
```
