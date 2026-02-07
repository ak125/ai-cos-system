# RAG Deployment — Connect automecanik-rag to Production

## Overview

This document describes how to deploy the RAG chat service and connect it to the live NestJS platform. The integration uses a **feature flag** pattern (`RAG_ENABLED` env var) so the RAG module can be toggled without code changes.

## Architecture

```
┌──────────────────────┐     HTTP/JSON      ┌──────────────────────────┐
│  nestjs-remix-mono   │ ──────────────────► │   automecanik-rag        │
│                      │                     │                          │
│  RagProxyModule      │  POST /chat         │  FastAPI (port 8000)     │
│  RagProxyService     │  POST /search       │  LangGraph pipeline      │
│  RagProxyController  │  GET  /health       │  Weaviate + Redis        │
│                      │                     │                          │
│  ChatWidget (React)  │                     │  352 knowledge docs      │
│  lazy-loaded         │                     │  all-MiniLM-L6-v2        │
└──────────────────────┘                     └──────────────────────────┘
```

**Flow:** User → ChatWidget → `POST /api/rag/chat` (NestJS) → `POST /chat` (FastAPI) → Weaviate hybrid search → Claude LLM generation → response back.

## Prerequisites

| Requirement | Details |
|---|---|
| Docker & Docker Compose | v2+ on the target server |
| automecanik-rag repo | Cloned on the RAG server |
| Network access | NestJS server must reach RAG server on port 8000 |
| API key | Shared `RAG_API_KEY` between both services |

## Step 1: Deploy the RAG Stack

On the RAG server:

```bash
cd automecanik-rag

# Create .env.prod from example
cp .env.prod.example .env.prod

# Edit .env.prod — set at minimum:
#   PROD_RAG_API_KEY=<strong-random-key>
#   ENV=prod

# Start the stack (rag-api + weaviate + redis)
docker compose -f docker-compose.prod.yml up -d

# Verify health
curl http://localhost:8000/health
# Expected: {"status": "healthy", "services": {"weaviate": {"status": "up"}, ...}}
```

### Production docker-compose highlights

- **rag-api**: Port 8000 exposed, 2 CPU / 2GB RAM, knowledge volume **read-only**
- **weaviate**: Internal network only, anonymous access **disabled**
- **redis**: Internal network only, 256MB maxmemory with LRU eviction
- **network**: `rag-internal` with `internal: true` (no external access to Weaviate/Redis)

## Step 2: Configure the NestJS Platform

In `nestjs-remix-monorepo`, set these environment variables:

```bash
# .env (or deployment env vars)
RAG_ENABLED=true
RAG_SERVICE_URL=http://<rag-server-ip>:8000
RAG_API_KEY=<same-key-as-PROD_RAG_API_KEY>
```

### What happens when RAG_ENABLED=true

1. `app.module.ts` loads `RagProxyModule` via spread pattern:
   ```typescript
   ...(process.env.RAG_ENABLED === 'true' ? [RagProxyModule] : [])
   ```
2. Three endpoints become available:
   - `POST /api/rag/chat` — forwards to FastAPI `/chat`
   - `POST /api/rag/search` — forwards to FastAPI `/search`
   - `GET /api/rag/health` — checks FastAPI `/health`
3. `ChatWidget` renders on all non-admin pages (lazy loaded)

### What happens when RAG_ENABLED=false (default)

- `RagProxyModule` is not loaded
- `/api/rag/*` endpoints return 404
- `ChatWidget` renders but calls fail gracefully (error message shown in widget)

## Step 3: Verify the Connection

```bash
# 1. Check RAG health through NestJS proxy
curl https://www.automecanik.com/api/rag/health

# 2. Send a test chat message
curl -X POST https://www.automecanik.com/api/rag/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Comment changer les plaquettes de frein ?", "sessionId": "test-1"}'

# Expected response:
# {
#   "answer": "Pour changer les plaquettes de frein...",
#   "sources": [...],
#   "sessionId": "...",
#   "confidence": 0.85
# }
```

## Field Mapping (NestJS ↔ FastAPI)

The `RagProxyService` handles field mapping between the two APIs:

| FastAPI `/chat` response | FastAPI `/chat/v2` response | NestJS DTO field |
|---|---|---|
| `context` | `response` | `answer` |
| `sources` | `sources` | `sources` |
| `session_id` | `session_id` | `sessionId` |
| `truth_metadata.composite_confidence` | `truth_metadata.composite_confidence` | `confidence` |

Mapping logic (fallback chain):
```typescript
const answer = data.response || data.answer || data.context || '';
const confidence = data.confidence ?? data.truth_metadata?.composite_confidence ?? 0;
```

## Safety Controls

### Kill switch (RAG side)

- `kill_switch.py` blocks all WRITE operations (indexing) in production
- Read operations (chat, search) are always allowed
- Controlled by `AI_PROD_WRITE=false` in docker-compose.prod.yml

### Feature flag (NestJS side)

- `RAG_ENABLED` env var — set to `false` to disable instantly (no redeploy needed, just restart)
- Module is completely excluded from the dependency injection graph when disabled

### Rate limiting

- NestJS ThrottlerGuard: 15 req/s, 100 req/min, 2000 req/h per IP
- RAG side: 60 RPM configured in `rag_config.yml`

### Quarantine mode

- RAG starts in `quarantine` mode — validates Weaviate connection, embedding dimensions, and corpus before accepting requests
- If validation fails: `fail_fast: true` → service exits (no silent degradation)

## Rollback Procedure

If issues arise after enabling RAG:

```bash
# Option 1: Disable via env var (fastest)
# Set RAG_ENABLED=false and restart NestJS

# Option 2: Stop RAG stack
cd automecanik-rag
docker compose -f docker-compose.prod.yml down

# NestJS will return 503 "Failed to connect to RAG service" for /api/rag/* endpoints
# ChatWidget will show error message but site continues to work normally
```

## Known Limitations (Phase 0)

1. **Claude generation is a placeholder** — `generate_node()` in `langgraph_flow.py` formats context without calling Claude LLM. Requires `ANTHROPIC_API_KEY` and implementation of actual Claude call (Phase 1).
2. **V1 endpoint only** — Currently connected to `/chat` (v1) which returns context-based responses. `/chat/v2` with full LangGraph pipeline is available but generate_node needs completion.
3. **No streaming** — Responses are returned in full. SSE streaming is configured in `rag_config.yml` but not yet wired to the NestJS proxy.

## Phase 1 Follow-up

After Phase 0 is validated in production:

- [ ] Complete Claude LLM generation in `generate_node()` (requires `ANTHROPIC_API_KEY`)
- [ ] Index all 352 knowledge documents into Weaviate prod class
- [ ] Switch proxy to `/chat/v2` for full LangGraph pipeline
- [ ] Add SSE streaming support in RagProxyController
- [ ] Add RAG health to platform `/health` endpoint
