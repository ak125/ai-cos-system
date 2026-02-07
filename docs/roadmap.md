# Roadmap Evolutive — Automecanik AI Platform

> Document vivant. Cocher chaque tache terminee. Suivre l'ordre des phases.
> Derniere mise a jour : 2026-02-07

## Etat actuel

| Element | Statut |
|---|---|
| Site e-commerce | LIVE en production (NestJS + Remix) |
| RAG (automecanik-rag) | DEV uniquement, pas connecte a la prod |
| Modules AI (AiContent, KG, RagProxy) | Desactives depuis P0.2 (2026-02-02) |
| ChatWidget | Code pret, pas monte dans le layout |
| generate_node (Claude LLM) | Placeholder, pas d'appel reel |
| Knowledge docs | 352 fichiers, non indexes dans Weaviate prod |

---

## Phase 0 — Connecter le RAG chat en lecture seule

**Objectif :** Le ChatWidget apparait sur le site, les utilisateurs posent des questions, le RAG repond avec le contexte des documents indexes.

**Risque :** Zero. Feature flag off par defaut. kill_switch bloque les ecritures.

### 0.1 Backend — Field mapping
- [ ] Editer `backend/src/modules/rag-proxy/rag-proxy.service.ts`
- [ ] Remplacer le bloc return (lignes 50-57) pour mapper `context`/`response` → `answer` et `truth_metadata` → `confidence`

### 0.2 Backend — Feature flag
- [ ] Editer `backend/src/app.module.ts`
- [ ] Decommenter l'import `RagProxyModule` (ligne 53)
- [ ] Remplacer le bloc desactive (lignes 180-184) par le spread conditionnel `...(process.env.RAG_ENABLED === 'true' ? [RagProxyModule] : [])`

### 0.3 Frontend — Monter le ChatWidget
- [ ] Editer `frontend/app/root.tsx`
- [ ] Ajouter `lazy, Suspense` a l'import React
- [ ] Ajouter le lazy import du ChatWidget
- [ ] Monter `<ChatWidget />` dans AppShell apres `<NotificationContainer />`

### 0.4 Deploiement RAG stack
- [ ] Sur le serveur RAG : `docker compose -f docker-compose.prod.yml up -d`
- [ ] Verifier : `curl http://localhost:8000/health`

### 0.5 Activer sur la plateforme
- [ ] Ajouter dans `.env` : `RAG_ENABLED=true`, `RAG_SERVICE_URL=http://<ip>:8000`, `RAG_API_KEY=<cle>`
- [ ] Restart NestJS
- [ ] Tester : `curl -X POST /api/rag/chat -d '{"message":"test"}'`

### 0.6 Valider en prod
- [ ] Ouvrir le site, verifier que le ChatWidget apparait (pas sur /admin)
- [ ] Envoyer un message test
- [ ] Verifier les logs NestJS (pas d'erreur 500)
- [ ] Si probleme : mettre `RAG_ENABLED=false` et restart

**Critere de passage Phase 1 :** Le ChatWidget repond avec des documents pertinents.

---

## Phase 1 — Generation Claude LLM + indexation complete

**Objectif :** Le RAG genere de vraies reponses avec Claude au lieu de juste retourner le contexte brut. Les 352 docs sont indexes.

### 1.1 Activer la generation Claude
- [ ] Ajouter `ANTHROPIC_API_KEY` dans `.env` du RAG
- [ ] Completer `generate_node()` dans `orchestrator/langgraph_flow.py` (ligne 251) — remplacer le placeholder par un appel Claude reel
- [ ] Tester avec `/chat/v2` endpoint

### 1.2 Indexer les documents
- [ ] Verifier la classe Weaviate `Prod_Chatbot` dans `rag_config.yml`
- [ ] Lancer l'indexation des 352 docs knowledge dans Weaviate
- [ ] Verifier le count : `curl http://localhost:8000/documents/count`

### 1.3 Basculer sur /chat/v2
- [ ] Modifier `rag-proxy.service.ts` : changer `/chat` → `/chat/v2`
- [ ] Le v2 inclut : guardrails, citations, refusal_reason, query_type
- [ ] Tester les guardrails (question hors domaine → refus poli)

### 1.4 Monitoring basique
- [ ] Ajouter les logs RAG dans le monitoring existant
- [ ] Surveiller le temps de reponse (< 3s acceptable)
- [ ] Surveiller le taux d'erreur sur `/api/rag/chat`

**Critere de passage Phase 2 :** Claude genere des reponses, 352 docs indexes, guardrails actifs.

---

## Phase 2 — Stabiliser la plateforme NestJS

**Objectif :** Corriger les problemes structurels identifies dans le code existant.

### 2.1 Consolider le cache Redis
- [ ] Auditer les 10 implementations de cache differentes
- [ ] Unifier vers une seule strategie (CacheModule existant)
- [ ] Documenter les TTL par domaine

### 2.2 Nettoyer les modules lourds
- [ ] VehiclesService (1,285 lignes) — decouper en sous-services si necessaire
- [ ] SeoModule (10 services) — verifier qu'il n'y a pas de duplication
- [ ] Auditer les imports circulaires

### 2.3 Tests
- [ ] Verifier la couverture de tests existante
- [ ] Ajouter des tests sur RagProxy (mock du service FastAPI)
- [ ] Ajouter un test e2e basique sur `/api/rag/health`

### 2.4 CI/CD
- [ ] Verifier que les GitHub Actions passent sur la branche
- [ ] Ajouter un check pour le build TypeScript
- [ ] Ajouter un check pour les tests

**Critere de passage Phase 3 :** Tests verts, CI passe, pas de regression.

---

## Phase 3 — Enrichir les fonctionnalites AI

**Objectif :** Tirer plus de valeur du RAG et des capacites AI.

### 3.1 Streaming SSE
- [ ] Activer le streaming dans `rag_config.yml` (deja configure)
- [ ] Ajouter un endpoint SSE dans `RagProxyController`
- [ ] Mettre a jour le ChatWidget pour afficher les reponses en streaming

### 3.2 Contexte vehicule
- [ ] Passer le vehicule selectionne (VehicleProvider) au ChatWidget
- [ ] Enrichir la requete RAG avec marque/modele/motorisation
- [ ] Filtrer les resultats Weaviate par vehicule

### 3.3 Reactiver les modules AI
- [ ] AiContentModule — feature flag `AI_CONTENT_ENABLED`
- [ ] KnowledgeGraphModule — feature flag `KG_ENABLED`
- [ ] Meme pattern spread que RagProxy

### 3.4 Knowledge Graph ↔ RAG
- [ ] Connecter les 83 noeuds KG existants au pipeline RAG
- [ ] Enrichir les reponses avec les relations diagnostiques

---

## Phase 4 — Orchestration AI-COS

**Objectif :** ai-cos-system devient le vrai chef d'orchestre.

### 4.1 Contrats partages
- [ ] Generer des types TypeScript depuis `specs/platform-rag.yaml`
- [ ] Generer des types Python (Pydantic) depuis le meme spec
- [ ] Les deux repos importent les types generes

### 4.2 Scripts cross-repo
- [ ] Script de health-check global (NestJS + RAG + Weaviate + Redis + Supabase)
- [ ] Script de deploiement coordonne
- [ ] Script de rollback automatique

### 4.3 Agent submissions
- [ ] Definir le pipeline de soumission d'agents
- [ ] Connecter au governance-vault pour validation
- [ ] Premier agent : agent de monitoring automatique

---

## Regles de progression

1. **Jamais sauter une phase** — chaque phase depend de la precedente
2. **Feature flag d'abord** — tout nouveau module passe par un env var
3. **Rollback en 30 secondes** — chaque changement doit pouvoir etre annule par un `=false` + restart
4. **Pas de big bang** — une modification a la fois, tester, valider, passer a la suivante
5. **Documenter ici** — cocher les cases au fur et a mesure dans ce fichier
