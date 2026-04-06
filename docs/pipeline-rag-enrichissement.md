# Pipeline RAG Enrichissement — Specification v2.1

> Source de verite pour le pipeline d'enrichissement systematique du corpus RAG gamme par gamme.
> Derniere mise a jour : 2026-04-06

## Contexte

Le corpus RAG Automecanik contient 241 fichiers gamme (237 en schema v5.0, 3 legacy v1, 1 autre). L'objectif est d'enrichir systematiquement chaque gamme, valider la qualite, et promouvoir les gammes conformes.

**Executeur** : RAG Lead via Paperclip (derogation experimentale, **Phase 0 + Phase 1**). Le statut governance-vault reste `NOT_APPROVED`. Phase 0/0b terminees avec succes (AUT-45, AUT-46 — 0 contamination, 0 derive). La derogation est etendue a Phase 1 avec les modes `audit_only`, `enrich_dry_run` et `enrich_write` (backup `_archive/` obligatoire avant toute ecriture). `qa_write` reste interdit jusqu'a mise a jour du verdict governance-vault.
**State machine** : `lifecycle.stage` dans le frontmatter uniquement (pas de tickets Paperclip)

---

## Etat des lieux

| Element | Statut | Emplacement |
|---------|--------|-------------|
| Schema gamme v5.0 (5 blocs + rendering + extensions) | Actif, 237/241 fichiers migres | `.spec/00-canon/gamme-md-schema.md` |
| Skill `/rag-check` | Operationnel, APPROVED tier-G1 | Diagnostic couverture R0-R8 |
| Skill `/rag-ops` | Operationnel, APPROVED tier-G1 | Operations pipeline RAG |
| Agent RAG Lead | `planned`, `NOT_APPROVED` | Orchestre le pipeline (futur) |
| Validators | Services NestJS (phase gates) | `rag-foundation-gate.service.ts`, `rag-admissibility-gate.service.ts` |
| QA Orchestrator | Actif, 12 cycles/jour | Coordonne les 3 suites QA (functional, visual, seo-tech) |
| Script `rag-enrich-from-web-corpus.py` | Utilise (voir `lifecycle.last_enriched_by`) | `scripts/rag/` |
| Script `rag-enrich-from-db.py` | Disponible | `scripts/rag/` |
| Script `ingest-oem-enriched-gammes.py` | Disponible | `scripts/rag/` |
| Script `rag-check.py` | Disponible | `scripts/seo/` |

---

## Pipeline cible (4 etapes)

### Etape 1 — Audit template (scoring multi-criteres)

**Qui** : `/rag-check` via Claude Code
**Roles couverts** : R0, R1, R3, R4, R5, R6, R7, R8

**Scoring par bloc** (pas juste la longueur) :

| Critere | Description |
|---------|-------------|
| `present` | Le bloc existe dans le frontmatter |
| `semantic_completeness` | Les champs attendus par type de bloc sont remplis (voir D5 — schema minimal) |
| `evidence_count` | Nombre de sources citees pour ce bloc |
| `confidence` | Proportion de champs `verified` vs `unverified` |
| `freshness` | Jours depuis `updated_at` (vert <30j, jaune 30-90j, rouge >90j) |
| `conflict_flag` | Sources contradictoires detectees |

Un bloc maintenance de 120 chars avec 0 source et 0 evidence est "faible" meme s'il est present.

**Priorisation** :
- Gammes a fort trafic SEO / fort volume de ventes en priorite
- Croiser avec `pieces_gamme.pg_display = '1'` + donnees GSC si disponibles
- Filtrer : gammes sans fichier > gammes legacy v1 > gammes v5.0 incompletes

**Sortie** : Tableau priorise avec score par bloc et action requise.

### Etape 2 — Enrichissement (Skills + LLM web search)

**Qui** : Skills `/rag-check --fix` + `/rag-ops` via Claude Code
**Comment** : WebSearch/WebFetch via outils MCP, scripts existants comme base

#### Hierarchie des sources

| Tier | Sources | Usage |
|------|---------|-------|
| A (autorite) | Constructeurs (Valeo, Bosch, SKF, Continental), docs techniques, normes ISO/SAE | Requis pour donnees techniques normatives, intervalles, compatibilites, securite |
| B (fiable) | Revendeurs (Oscaro guides, Mister Auto), guides atelier, contenus experts structures | Suffisant pour criteres choix, symptomes, procedures generales |
| C (generaliste) | Wikipedia, Vroomly, blogs, forums | Utile pour L2 uniquement — FAQ, termes courants, confusions |

**Regles de combinaison Tier B/C** (D7) :

| Contexte | Tier C seul | Tier B seul | Tier A requis |
|----------|-------------|-------------|---------------|
| Symptome courant | Non | **Oui** | Non |
| Critere choix non normatif | Non | **Oui** | Non |
| Procedure generale non critique | Non | **Oui** | Non |
| Valeur chiffree (intervalle, dimension) | **Jamais** | Corroboration requise | **Oui** |
| Norme ISO/SAE/OEM | **Jamais** | **Jamais** | **Oui** |
| Consigne securite | **Jamais** | **Jamais** | **Oui** |

**Regle absolue** : Une source Tier C ne peut JAMAIS justifier seule une donnee technique.

**Fallback Tier A** : Si un champ exige Tier A et qu'aucune source Tier A n'est trouvee par web search :
- Marquer le champ `requires_manual_source: true`
- Lister dans `enrichment_report.json` sous `pending_manual_sources[]`
- Processus de sourcing manuel separement (hors pipeline automatique)

**Restriction du fallback** : `requires_manual_source` ne s'applique qu'aux champs **non critiques pour la securite, la conformite ou la specification technique structurante** :
- **Fallback autorise** (ne bloque pas L1) : valeurs chiffrees informatives (poids, dimensions non bloquantes), intervalles indicatifs courants
- **Fallback INTERDIT** (bloque L1 sans Tier A) : normes ISO/SAE/OEM, consignes securite, valeurs reglementaires, specifications dimensionnelles bloquantes pour la compatibilite

#### Requetes de recherche par bloc

| Bloc | Requetes |
|------|----------|
| domain | `{piece} role mecanique`, `{piece} difference avec`, `{piece} norme OEM` |
| selection | `{piece} criteres choix`, `{piece} erreurs achat`, `{piece} dimensions specification` |
| diagnostic | `{piece} symptomes usure`, `{piece} signes defaillance` |
| maintenance | `{piece} intervalle remplacement`, `{piece} entretien` |
| installation | `{piece} remplacement procedure`, `{piece} depose repose` |

#### Anti-hallucination

Chaque donnee technique DOIT avoir un champ `source_url`. Format de sortie force :

```yaml
maintenance:
  interval:
    value: "15000-30000 km"
    source_url: "https://www.bosch.com/..."
    source_tier: A
    confidence: verified
  wear_signs:
    - label: "Voyant huile allume"
      source_url: "https://..."
      confidence: verified
    - label: "Bruit moteur anormal"
      source_url: null
      confidence: unverified  # PAS absent — marque explicitement
```

Toute donnee sans `source_url` est marquee `confidence: unverified` au lieu d'etre supprimee.

#### Provenance par bloc (pas juste globale)

```yaml
_sources:
  domain:
    - type: manufacturer
      url: https://www.valeo.com/...
      accessed_at: 2026-04-06
      tier: A
  maintenance:
    - type: retailer_guide
      url: https://www.oscaro.com/...
      accessed_at: 2026-04-06
      tier: B
_conflicts:
  - block: maintenance
    field: interval.value
    conflict_type: technical_conflict
    run_id: "uuid-du-run"
    existing_value: "15000 km"
    new_value: "20000 km"
    existing_sources:
      - url: "https://www.bosch.com/..."
        tier: A
    new_sources:
      - url: "https://www.valeo.com/..."
        tier: A
    resolution_status: open
    human_review_required: true
    created_at: "2026-04-06"
    resolved_by: null
    resolution: null
_review_required: true
_enrichment_log:
  - date: 2026-04-06
    run_id: "uuid-du-run"
    agent: skill:rag-check
    blocks_added: [maintenance, diagnostic]
    blocks_modified: [selection]
    blocks_unchanged: [domain, installation]
```

**Note** : Le format `_sources` per-bloc est introduit incrementalement gamme par gamme pendant l'enrichissement. Les gammes non encore enrichies conservent l'ancien format.

#### Merge non destructif par champ (D3)

| Type de donnee | Regle |
|----------------|-------|
| **Champ scalaire** (role, interval.value) | Ne jamais ecraser si `confidence: verified`. Ecraser si vide, `unverified`, ou `needs_refresh` et nouvelle donnee plus fiable |
| **Entree de liste identifiee** (symptom avec id S1, confusion_with par term) | Merge par identifiant — ajouter les nouvelles, ne jamais supprimer les existantes verified |
| **Liste sans identifiant** (anti_mistakes, good_practices) | Remplacement controle de la liste complete avec comparaison de fiabilite. L'ancienne liste est conservee dans le diff |
| **Objet imbrique** (cost_range, interval) | Merge champ par champ a l'interieur de l'objet |
| **Source individuelle** (_sources par bloc) | Ajouter les nouvelles sources, ne jamais supprimer les existantes. Mettre a jour `accessed_at` si re-verification |

**Invariant** : Toujours conserver les metadonnees de sourcing les plus fortes.

#### Gestion des conflits (D4)

| Type | Definition | Bloque L1 ? | Traitement |
|------|-----------|-------------|------------|
| `minor_variation` | Variation de formulation sans impact metier | **Non** | Normaliser, choisir formulation la plus precise |
| `technical_conflict` | Valeur technique divergente (ex: intervalle 15k vs 20k km) | **Oui** | Conserver dans `_conflicts`, `conflict_flag: true` |
| `safety_conflict` | Procedure / intervalle / risque contradictoire | **Oui** | Idem + `_review_required: true` + priorite revue humaine |

Schema complet : voir `.spec/00-canon/conflict.schema.yaml`

#### Regles d'execution

- Max 1 gamme par invocation
- Budget estimatif initial, a recalibrer apres dry-run Phase 0 et pilote Phase 1
- Cadence initiale plafonnee a 10 gammes/jour jusqu'a stabilisation du taux de promotion, du cout moyen reel et du taux de conflits
- Idempotence : relancer "Enrichir gamme {alias}" ne duplique jamais les FAQ, n'ecrase pas les sources verified, ne reinjecte pas les memes paragraphes
- Diff avant ecriture : toujours produire un diff logique (blocs ajoutes, modifies, sources ajoutees, inchanges)
- Anti-duplication : interdire les repetitions entre domain, selection, diagnostic, maintenance, installation, rendering
- Blocage semantique : si la gamme melange plusieurs sous-types de pieces ou technologies, stopper et ouvrir un commentaire de revue

### Etape 3 — Validation QA

**Qui** : `/rag-check` (scoring par role R*) + services NestJS (phase gates)

**Flux par defaut** : R3 (Conseils) + R4 (Reference) + R6 (Guide Achat) uniquement.
R0/R1 invoques seulement si l'enrichissement impacte le maillage, la compatibilite vehicule, ou le rendering router/page.

#### Deux scores distincts (D2)

| Score | Mesure | Criteres |
|-------|--------|----------|
| `qa_score` | Qualite structurelle et redactionnelle | Structure, clarte, non-duplication, adequation template, longueur |
| `evidence_score` | Qualite factuelle et sourcing | Tier source, corroboration, source_url present, confidence verified |

**Seuils de promotion** (initiaux, ajustables apres pilote) :

| Type de bloc | qa_score min | evidence_score min |
|-------------|-------------|-------------------|
| Critique (domain, selection, maintenance) | **>= 75** | **>= 70** |
| Non-critique (diagnostic, installation) | >= 65 | >= 55 |

#### Classification gamme par taux de blocs admissibles (calibre Phase 0b)

| Taux blocs admissibles | Classification | Exemple Phase 0b |
|------------------------|---------------|-----------------|
| < 40% | `ENRICHMENT_REQUIRED` | bouchon-de-vidange (33%) |
| 55-70% | `READY_WITH_LIMITS` | vanne-egr (67%) |
| >= 90% | `READY` / `PROMOTE_CANDIDATE` | filtre-a-huile (93%) |

> Seuil `READY_WITH_LIMITS` ajuste a 55% apres calibrage Phase 0b (initialement 65%).

#### Blocs critiques pour promotion L1 (D1)

**Critiques** (DOIVENT satisfaire tous les criteres) : `domain`, `selection`, `maintenance`
**Non-critiques** (peuvent rester L2) : `diagnostic`, `installation` — sauf instruction securite forte ou procedure a risque

#### Schema minimal obligatoire par bloc (D5)

| Bloc | Champs minimaux |
|------|----------------|
| `domain` | `role` (>80 chars), `confusion_with` (>= 2) |
| `selection` | `criteria` (>= 3), `anti_mistakes` (>= 2) |
| `maintenance` | `interval` (non-null), `wear_signs` (>= 2) |
| `diagnostic` | `symptoms` (>= 3 avec severity), `causes` (>= 2) |
| `installation` | `steps` (>= 3) OU `precautions` (si difficulty: expert) |

Bloc sans minimum structurel = automatiquement `incomplete` dans le scoring.

#### Gate anti-regression SEO (D8)

Checks explicites avant promotion :

| # | Check | Testable par |
|---|-------|-------------|
| 1 | `META.title` non supprime | Diff frontmatter avant/apres |
| 2 | `META.description` non supprime | Diff frontmatter |
| 3 | `rendering.faq` non degradee si elle existait | Pas de baisse sous le minimum structurel ; pas de perte des questions pivots existantes ; fusions de doublons autorisees si couverture semantique conservee |
| 4 | Pas de duplication Hn entre blocs enrichis | Scan titres inter-blocs |
| 5 | Conservation termes pivots metier | Intersection keywords avant/apres >= 80% |
| 6 | Aucune sortie hors intention R1/R6 prevue | Verification `intent_targets` inchange |
| 7 | Mapping `domain` → `__seo_reference` intact | Validation structure post-enrichissement |
| 8 | Mapping `selection` → `__seo_gamme_purchase_guide` intact | Idem |

Si un check echoue → bloquer promotion, marquer `v5_pending_review`.

**Fallback si validation echoue** : La gamme est marquee `v5_pending_review`, le pipeline passe a la gamme suivante. Les validations sont corrigees dans une iteration ulterieure.

### Etape 4 — Promotion et indexation

**Qui** : Mode `qa_write` via Claude Code

#### Conditions de promotion L2 → L1

Tous les criteres doivent etre remplis :

- [ ] `qa_score` >= seuil sur tous les blocs critiques
- [ ] `evidence_score` >= seuil sur tous les blocs critiques
- [ ] Blocs critiques ont des sources Tier A ou corroboration interne (sauf champs couverts par le fallback D7)
- [ ] Aucun `technical_conflict` ou `safety_conflict` ouvert (`_conflicts` resolus)
- [ ] Schema v5.0 valide (YAML/frontmatter)
- [ ] Pas de placeholders
- [ ] `_review_required: false`
- [ ] Longueur minimale utile sur blocs requis
- [ ] 8 checks SEO passes (D8)
- [ ] Aucun champ securite/norme/conformite avec `requires_manual_source: true` non resolu

Si un critere manque → conserver `truth_level: L2` avec commentaire structure des gaps restants.

**Regle canonique** : La promotion L2 → L1 n'est autorisee que :
- **Quand** : au moment de la transition `v5_enriched → v5_qa_passed`
- **Par quel mode** : exclusivement `qa_write` (jamais `enrich_write`, jamais manuellement)
- **Si** : tous les criteres ci-dessus sont remplis

#### Regeneration conditionnelle

Pas systematique — seulement si les blocs modifies impactent les keywords/content :

| Blocs modifies | Action |
|----------------|--------|
| `domain` ou `selection` | Regenerer KP (`/kp {alias}`) |
| `maintenance` ou `rendering` | Regenerer contenu (`/content-gen {alias}`) |
| `installation` seul | Pas de regeneration KP/content |

#### Truth levels

| Niveau | Definition |
|--------|-----------|
| L2 | Enrichi automatiquement avec sources externes, non valide metier |
| L1 | Valide par QA + corrobore par source Tier A ou donnee interne fiable |

---

## State machine (lifecycle.stage)

### Matrice operationnelle (E1)

| stage | cycle_terminal | reopenable | indexable | enrichissable | promouvable L1 | revue humaine |
|-------|----------------|------------|-----------|---------------|----------------|---------------|
| `v5_ssot` | non | — | oui | oui | non | non |
| `v5_audited` | non | — | oui | oui | non | non |
| `v5_enriched` | non | — | non | oui (re-enrichissement) | non | non |
| `v5_qa_passed` | non | — | oui | oui | **oui** (seul stage) | non |
| `v5_indexed` | **oui** | **oui** (→ v5_ssot) | oui | oui (nouveau cycle) | non | non |
| `v5_blocked` | non | non (revue requise) | non | non | non | **oui** |
| `v5_pending_review` | non | non (revue requise) | non | limite (champs specifiques) | non | **oui** |

### Transitions autorisees (E2)

```
v5_ssot ──────────→ v5_audited
v5_audited ────────→ v5_enriched
v5_enriched ───────→ v5_qa_passed
v5_qa_passed ──────→ v5_indexed

# Toute etape peut bloquer
v5_audited ────────→ v5_blocked
v5_enriched ───────→ v5_blocked
v5_enriched ───────→ v5_pending_review
v5_qa_passed ──────→ v5_pending_review

# Recovery
v5_blocked ────────→ v5_audited        (apres resolution + re-audit)
v5_pending_review ─→ v5_enriched       (apres revue humaine accept)
v5_pending_review ─→ v5_blocked        (apres revue humaine reject)

# Nouveau cycle
v5_indexed ────────→ v5_ssot           (nouveau cycle enrichissement)
```

**Transitions INTERDITES** :
- `v5_blocked` → `v5_indexed` (impossible sans re-audit complet)
- `v5_blocked` → `v5_qa_passed` (impossible sans re-enrichissement)
- `v5_ssot` → `v5_qa_passed` (impossible sans enrichissement)
- `v5_ssot` → `v5_indexed` (impossible sans pipeline complet)
- Tout saut d'etape (v5_audited → v5_indexed, etc.)

### Relation truth_level / lifecycle.stage (E3)

| truth_level | stages autorises |
|-------------|-----------------|
| L2 | `v5_ssot`, `v5_audited`, `v5_enriched`, `v5_qa_passed`, `v5_blocked`, `v5_pending_review` |
| L1 | `v5_qa_passed`, `v5_indexed` |

**Combinaisons invalides** :
- L1 + `v5_ssot` — pas encore enrichi
- L1 + `v5_enriched` — pas encore valide QA
- L1 + `v5_blocked` — bloque = pas valide
- L1 + `v5_pending_review` — en attente = pas confirme

---

## Modes d'execution (E4)

| Mode | Fichiers modifies | Artefacts produits | Promotion autorisee |
|------|-------------------|-------------------|---------------------|
| `audit_only` | Non | `enrichment_report.json` (scores seuls) | Non |
| `enrich_dry_run` | Non | `enrichment_report.json` + diff preview | Non |
| `enrich_write` | Oui (gamme .md) | `enrichment_report.json` + backup `_archive/` | Non (stage → v5_enriched) |
| `qa_only` | Non | Verdicts validators dans report | Non |
| `qa_write` | Oui (stage update) | Report + stage transition | **Oui** (si criteres remplis) |
| `index_ready_check` | Non | Checklist pre-indexation | Non |

**Regles** :
- Tout mode `*_write` produit d'abord un `*_dry_run` implicite avant ecriture
- Seul `qa_write` peut promouvoir `truth_level` a L1
- `enrich_write` ne fait que transitionner le stage vers `v5_enriched`

### Backup obligatoire (E4)

Tout mode `*_write` cree un backup horodate dans `_archive/` AVANT ecriture :

```
_archive/{alias}/{timestamp}.{stage_before}.{execution_mode}.md
```

Exemple : `_archive/alternateur/2026-04-06T14-32-10Z.v5_ssot.enrich_write.md`

Le backup contient le fichier source complet + metadata header : `alias`, `timestamp`, `stage_before`, `execution_mode`, `run_id`.

### Identifiant de run (E4b)

Chaque execution genere un `run_id` unique (UUID v4), propage dans :
- `enrichment_report.json` (champ `run_id`)
- Le backup `_archive/` (header metadata)
- Les entrees `_conflicts[]` (champ `run_id`)
- Les logs de validation QA
- Le champ `lifecycle.last_enriched_run_id` dans le frontmatter de la gamme

### Sortie machine-readable (D9)

Chaque run produit un `enrichment_report.json`. Schema formel : `.spec/00-canon/enrichment-report.schema.json`

---

## Garde-fous

| Garde-fou | Implementation |
|-----------|---------------|
| Anti-hallucination | `source_url` + `confidence` obligatoires par donnee technique |
| Merge non destructif | Regles par type de donnee (D3), jamais ecraser `verified` |
| Anti-duplication | Check inter-blocs avant ecriture |
| Blocage semantique | Stop si gamme multi-types/multi-techno |
| Conflits | 3 types (D4), conserves pas arbitres, bloquent L1 si technical/safety |
| Backup | `_archive/{alias}/{timestamp}.{stage}.{mode}.md` avant tout `*_write` |
| Gate SEO | 8 checks testables (D8) avant promotion |
| Seuil stop global | >20% du lot en blocked/pending_review → suspension (D10) |
| Stratification lots | Par densite de sources (courante/niche/specialiste), seuil stop par strate |
| Fallback Tier A | `requires_manual_source` restreint aux champs non-securite/non-normatifs (D7) |
| Run traceability | `run_id` UUID propage dans tous les artefacts (E4b) |

---

## Roles de revue (E6)

**Roles canoniques** :
- **Tech Lead** : Responsable technique du pipeline enrichissement. Decisions sur conflits, promotions, blocages.
- **SEO Lead** : Responsable SEO. Decisions sur regressions SEO, intent, maillage.
- **Expert Metier** : Specialiste automobile. Decisions sur sourcing Tier A, validations techniques metier.

| Situation | Owner | Sortie obligatoire |
|-----------|-------|-------------------|
| `technical_conflict` | Tech Lead ou Expert Metier | `accept_existing` / `accept_new` / `merge` / `needs_manual_research` |
| `safety_conflict` | Tech Lead (**obligatoire, pas delegable**) | `accept_existing` / `accept_new` / `rewrite` / `needs_manual_research` |
| SEO regression detectee | SEO Lead | `accept` / `reject` / `rewrite` |
| Promotion bloquee (`v5_blocked`) | Tech Lead | `unblock_to_audit` / `archive` / `needs_manual_research` |
| `pending_manual_sources` | Expert Metier | `source_added` / `field_removed` / `accept_without_tier_a` (restriction D7 : jamais pour securite, normes, conformite, compatibilite bloquante) |

**Regle** : Les etats `v5_blocked` et `v5_pending_review` ne s'accumulent pas silencieusement. Un rapport hebdomadaire liste les gammes en attente de revue avec leur age.

---

## Seuil stop global et procedure de reprise (D10)

**Seuil** : >20% du lot en `v5_blocked` ou `v5_pending_review` → suspension.

**Procedure de reprise** :
1. Geler le lot suivant
2. Isoler les gammes bloquees/pending_review
3. Produire un rapport de causes racines (patterns communs des echecs)
4. Corriger les regles ou prompts du pipeline
5. Relancer un micro-lot de validation (3 gammes) avant reprise
6. Si micro-lot OK → reprendre la cadence normale

**Stratification** : Stratifier les lots par densite de sources attendue (courante / niche / specialiste). Appliquer le seuil stop **par strate**, pas globalement sur un lot mixte.

---

## Sequence de deploiement (E7)

| Phase | Taille lot | Condition de passage |
|-------|-----------|---------------------|
| Phase 0 — Dry-run | **1 gamme** (la plus faible) | Prompt exact valide, format sortie conforme, pas de derive |
| Phase 0b — Echantillon | **3 gammes** (faible + moyenne + quasi-complete) | Resultats coherents sur les 3 profils, seuils D2 calibres |
| Phase 1 — Pilote | **5 gammes** (prioritaires par trafic SEO) | Taux promotion >= 40%, 0 regression SEO, cout moyen mesure |
| Phase 2 — Stabilisation | **lots de 5** | Metriques stables sur 3 lots consecutifs |
| Phase 3 — Montee en charge | **lots de 10 max** | Metriques vertes, cadence <= 10/jour |

```
Phase 0 : Dry-run 1 gamme (la plus faible)
    → Valider prompt, format, pas de derive
    → Mesurer cout reel, identifier les points de friction

Phase 0b : Echantillon 3 gammes (faible, moyenne, quasi-complete)
    → Comparer avant/apres humainement
    → Calibrer les seuils D2 (qa_score, evidence_score)
    → Valider que D7 (Tier A fallback) fonctionne

Phase 1 : Pilote 5 gammes prioritaires (fort trafic SEO)
    → Evaluer taux de promotion, cout moyen, conflits
    → Ajuster les regles si necessaire

Phase 2 : Lots de 5, stratifies par densite de sources
    → 3 lots consecutifs stables → passage Phase 3

Phase 3 : Lots de 10/jour, cadence conditionnelle
    → Monitoring continu, seuil stop D10 actif
    → Rapport hebdomadaire gammes en review
```

---

## Verification

- [ ] Dry-run manuel sur 1 gamme (Phase 0)
- [ ] Comparaison avant/apres sur echantillon 3 gammes (Phase 0b)
- [ ] Score audit avant/apres enrichissement
- [ ] Diff du fichier .md (blocs ajoutes vs modifies)
- [ ] Sources Tier A presentes sur blocs critiques (ou `requires_manual_source` pour non-bloquants)
- [ ] Pas de conflit `technical_conflict` ou `safety_conflict` ouvert
- [ ] Validators produisent un verdict par bloc (pas global)
- [ ] `enrichment_report.json` conforme au schema
- [ ] `run_id` present dans tous les artefacts
- [ ] Promotion L1 uniquement si tous les criteres remplis
- [ ] Gate SEO 8/8 checks passes
- [ ] Backup `_archive/` present avant chaque ecriture

---

## Schemas associes

| Schema | Fichier |
|--------|---------|
| enrichment_report.json | `.spec/00-canon/enrichment-report.schema.json` |
| _conflicts[] | `.spec/00-canon/conflict.schema.yaml` |
| gamme.md v5.0 | `.spec/00-canon/gamme-md-schema.md` |
