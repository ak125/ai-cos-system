# ADR-001: Multi-Repository Architecture

**Date:** 2026-02-07
**Status:** Accepted
**Deciders:** Founder

## Context

We are building an AI-driven company that requires:
- A product platform (web application + APIs)
- An AI agent management system
- A governance and compliance framework

We need to decide how to organize the codebase.

## Options Considered

### Option A: Single Monorepo
All code in one repository using workspaces (e.g., Turborepo, Nx).

**Pros:** Single CI/CD, atomic cross-cutting changes, unified versioning
**Cons:** Tight coupling, complex CI, permission management is harder, single point of failure

### Option B: Multi-Repo with Orchestrator (Chosen)
Separate repositories for each domain, with a central orchestration repo.

**Pros:** Clear domain boundaries, independent deployment, focused ownership, simpler per-repo CI
**Cons:** Cross-repo changes need coordination, shared code needs contracts, more repos to manage

### Option C: Fully Independent Repos
Separate repositories with no central coordination.

**Pros:** Maximum independence
**Cons:** No shared standards, integration drift, harder to maintain consistency

## Decision

**Option B — Multi-repo with `ai-cos-system` as the orchestrator.**

Four repositories:
1. `ai-cos-system` — Orchestration, contracts, config, documentation
2. `nestjs-remix-monorepo` — Core product platform
3. `agent-submissions` — AI agent lifecycle management
4. `governance-vault` — Governance, policies, compliance

## Rationale

- **Separation of concerns**: Each subsystem has a distinct domain and lifecycle
- **AI-native**: Agents, governance, and platform are fundamentally different domains with different change frequencies
- **Scalable team model**: As the AI-driven company grows, each subsystem can evolve independently
- **Governance isolation**: Keeping governance separate ensures rules can't be circumvented by platform changes
- **Orchestrator value**: `ai-cos-system` prevents drift by defining shared contracts and standards

## Consequences

- Must maintain API contracts in `ai-cos-system/specs/` and keep them in sync
- Cross-repo changes require coordination (documented in integration-map.md)
- CI/CD must be configured per-repo with cross-repo triggers for integration
- Shared schemas and types need a distribution mechanism (npm packages or spec files)
