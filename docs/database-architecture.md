# Database Architecture

Supabase PostgreSQL database `massdoc` — the central data store for the Automecanik platform.

## Overview

| Metric | Value |
|---|---|
| **Provider** | Supabase Pro (ak125's Org) |
| **Project** | massdoc |
| **Engine** | PostgreSQL |
| **Tables** | 200+ |
| **Largest tables** | `pieces_relation_type` (146M rows, 36GB), `pieces_ref_search` (73M, 18GB), `pieces_criteria` (17.6M, 4.9GB) |
| **Total estimated size** | ~68GB+ |
| **Origin** | Migrated from MySQL (conversion automatique) |

## Data Domains

### 1. Vehicle Reference (auto_*)

The vehicle hierarchy: Brand → Model → Type (motorization).

```
auto_marque (117 brands)
    └── auto_modele (5,745 models)
        └── auto_type (48,918 types/motorizations)
            └── auto_type_number_code (165K cross-references)
```

| Table | Rows | Purpose |
|---|---|---|
| `auto_marque` | 117 | Vehicle manufacturers (Renault, Peugeot, BMW...) |
| `auto_modele` | 5,745 | Vehicle models (Clio, 308, Serie 3...) |
| `auto_modele_group` | 1,957 | Model groups/series |
| `auto_type` | 48,918 | Specific motorizations (1.5 dCi 90cv, 2.0 TDI...) |
| `auto_type_number_code` | 165,082 | External cross-reference codes (TecDoc KTYPNR) |
| `auto_type_motor_fuel` | 26 | Fuel types |
| `cars_engine` | 35,661 | Engine reference data |

### 2. Parts Catalog (pieces_*)

The core product catalog — 3.5M parts with criteria, compatibility, pricing, and media.

```
pieces (3.5M parts)
    ├── pieces_criteria (17.6M criteria)
    ├── pieces_relation_type (146M vehicle compatibilities)
    ├── pieces_relation_criteria (157M criteria-vehicle links)
    ├── pieces_ref_search (73M search references)
    ├── pieces_ref_ean (3M EAN barcodes)
    ├── pieces_media_img (4.6M images)
    ├── pieces_price (442K pricing entries)
    ├── pieces_list (1.8M listings)
    └── pieces_gamme (9.6K product families)
```

| Table | Rows | Size | Purpose |
|---|---|---|---|
| `pieces` | 3,520,874 | 1.5 GB | Main parts table |
| `pieces_criteria` | 17,603,698 | 4.9 GB | Technical criteria per part |
| `pieces_relation_type` | 146,373,485 | 13 GB | Part ↔ vehicle compatibility |
| `pieces_relation_criteria` | 157,858,492 | 36 GB | Criteria ↔ vehicle links |
| `pieces_ref_search` | 73,151,596 | 18 GB | OEM/search reference cross-ref |
| `pieces_media_img` | 4,624,945 | 1 GB | Product images |
| `pieces_price` | 442,173 | 344 MB | Pricing data |
| `pieces_list` | 1,811,579 | 394 MB | Part listings |
| `pieces_gamme` | 9,682 | 10 MB | Product families/ranges |
| `pieces_marque` | 992 | 656 KB | Part brands |
| `pieces_ref_ean` | 3,028,577 | 897 MB | EAN barcodes |
| `pieces_ref_brand` | 5,853 | 1.4 MB | Brand references |
| `pieces_criteria_group` | 4,266 | 1.5 MB | Criteria groupings |

### 3. SEO Engine (__seo_*)

Massive SEO system — page generation, keyword management, quality scoring, indexation tracking.

```
SEO Pipeline:
  __seo_keywords → __seo_page (321K pages)
       │               │
       ▼               ▼
  __seo_gamme     __seo_entity → __seo_entity_score_v10
       │               │
       ▼               ▼
  __seo_gamme_*   __seo_audit_log
```

**Core tables:**

| Table | Rows | Purpose |
|---|---|---|
| `__seo_page` | 321,838 | Generated SEO pages |
| `__seo_keywords` | 7,164 | Keyword database with classification |
| `__seo_keywords_clean` | 1,642 | Cleaned keywords from Google Keyword Planner |
| `__seo_gamme` | 131 | Product range SEO content |
| `__seo_gamme_car` | 118 | Vehicle-specific range pages |
| `__seo_marque` | 35 | Brand SEO pages |
| `__seo_observable` | 65 | Diagnostic SEO pages (symptom/sign/DTC) |
| `__seo_reference` | 133 | SEO reference data |

**Quality & scoring:**

| Table | Purpose |
|---|---|
| `__seo_business_rules` (90) | Rules B1-B4, A1-A4, C1-C4, M1-M3 |
| `__seo_penalty_matrix` (57) | Unified penalty matrix per rule |
| `__seo_zone_config` (13) | Zone coefficients + severity |
| `__seo_family_checklist` (37) | Required fields per product family |
| `__seo_product_fields` (83) | Unified required fields |
| `__seo_content_length_config` (5) | Optimal content lengths per zone |
| `__seo_claims_tiered` (46) | Tiered claims verification |
| `__seo_confusion_pairs` (124) | Confusion pair detection |
| `__seo_contradiction_pairs` (38) | Contradiction detection |
| `__seo_cooccurrence_rules` (41) | Co-occurrence validation |

**Indexation & crawl:**

| Table | Purpose |
|---|---|
| `__seo_indexation_status` | Current indexation status per page |
| `__seo_index_history` | Daily snapshots for tracking losses |
| `__seo_crawl_hub` | Crawl hub configuration |
| `__seo_crawl_log` | Googlebot crawl log |
| `__seo_sitemap_file` | Generated sitemap files |
| `__sitemap_p_link` (473K) | Product page sitemap links |
| `__sitemap_motorisation` (12.7K) | Vehicle motorization sitemaps |

**Content generation:**

| Table | Purpose |
|---|---|
| `__seo_gamme_purchase_guide` (221) | AI-generated purchase guides |
| `__seo_gamme_conseil` (772) | Product range advice content |
| `__seo_gamme_info` (986) | Product range information |
| `__seo_generation_log` (19) | Content generation audit |

### 4. Knowledge Graph (kg_*)

Graph-based reasoning engine for automotive diagnostics.

```
kg_nodes (83 nodes: Vehicle, System, Observable, Fault, Action, Part)
    │
    └── kg_edges (72 edges: versioned relationships)
            │
            ├── kg_reasoning_cache (7 cached diagnostics)
            ├── kg_safety_triggers (13 safety rules)
            └── kg_cases / kg_case_outcomes (diagnostic cases)
```

| Table | Rows | Purpose |
|---|---|---|
| `kg_nodes` | 83 | Graph nodes (72 columns — rich metadata) |
| `kg_edges` | 72 | Versioned relationships between nodes |
| `kg_reasoning_cache` | 7 | Cached diagnostic inference results |
| `kg_safety_triggers` | 13 | Safety-critical trigger rules |
| `kg_cases` | 0 | Diagnostic case definitions |
| `kg_case_outcomes` | 0 | Case resolution outcomes |
| `kg_audit_log` | 0 | Graph modification history |
| `kg_review_queue` | 0 | Pending human review items |
| `kg_truth_labels` | 0 | Ground truth for validation |
| `kg_feedback_events` | 0 | User feedback on diagnostics |
| `kg_learning_log` | 0 | Learning from feedback loop |
| `kg_weight_adjustments` | 0 | Edge weight tuning |
| `kg_engine_families` | 10 | Engine family groupings |

### 5. Diagnostic System (__diag_*)

Symptom-to-part mapping for customer-facing diagnostics.

| Table | Rows | Purpose |
|---|---|---|
| `__diag_symptoms` | 31 | Detectable symptoms catalog |
| `__diag_symptom_family` | 35 | Symptom → part family mapping |
| `__diag_context_questions` | 5 | Follow-up questions to refine diagnosis |
| `__diag_related_parts` | 7 | Parts often replaced together |
| `__diag_safe_phrases` | 17 | Safe response phrases |

### 6. RAG Knowledge (__rag_*)

Retrieval-Augmented Generation — currently seeded, to be expanded.

| Table | Rows | Purpose |
|---|---|---|
| `__rag_knowledge` | 5 | Domain knowledge entries |
| `kg_rag_mapping` | 0 | KG ↔ RAG synchronization mapping |
| `kg_rag_sync_log` | 0 | Sync operation history |

### 7. E-Commerce (___xtr_*)

Legacy e-commerce tables migrated from MySQL.

| Table | Rows | Purpose |
|---|---|---|
| `___xtr_customer` | 59,122 | Customer accounts |
| `___xtr_customer_billing_address` | 59,109 | Billing addresses |
| `___xtr_customer_delivery_address` | 59,110 | Delivery addresses |
| `___xtr_order` | 1,598 | Orders |
| `___xtr_order_line` | 2,407 | Order line items |
| `___xtr_invoice` | 1 | Invoice template |
| `___xtr_msg` | 14,256,248 | Messages (24GB — needs cleanup?) |
| `___xtr_supplier` | 70 | Suppliers |
| `___xtr_delivery_agent` | 1 | Shipping carrier |

### 8. Import Pipeline (stg_* → norm_* → xref_*)

CQRS-pattern data import: staging → normalization → cross-reference resolution.

```
External data (TecDoc, suppliers)
        │
        ▼
  stg_* (Couche A: raw staging — NEVER update/delete)
  ├── stg_article
  ├── stg_brand
  ├── stg_compatibility
  └── stg_vehicle
        │
        ▼
  norm_* (Couche B: normalized with business fingerprint)
  ├── norm_article
  ├── norm_brand
  └── norm_vehicle
        │
        ▼
  xref_* (Couche C: identity resolution — external → internal)
  ├── xref_article
  ├── xref_brand
  └── xref_vehicle
        │
        ▼
  Production tables (pieces, auto_type, etc.)
```

**Supporting tables:**

| Table | Purpose |
|---|---|
| `natural_key_*` | Business-key matching when external IDs change |
| `decision_*` | Auditable import decisions |
| `__staging_*` | Pre-merge staging for mappings |
| `__import_batch_contract` | Batch completeness guarantees (≥95%) |
| `__import_gate_status` | 5-gate validation pipeline |
| `__import_manifest` | File-level tracking |
| `__import_proof` | Cryptographic import proofs |
| `__quarantine_*` | Quarantined items pending review |

### 9. Read Model / CQRS (rm_*)

Optimized serving layer — pre-computed data for fast page rendering.

| Table | Purpose |
|---|---|
| `rm_listing` | 1 row per listing page (gamme_id, vehicle_id) |
| `rm_listing_content` | Heavy content (FAQ, guides) — lazy loaded |
| `rm_listing_products` | Partitioned by gamme_id for performance |
| `rm_product` | Product dimension table |
| `rm_facets` | Pre-computed facets (brands_top, filters) |
| `rm_oem_top` | Top OEM references per vehicle/range |
| `rm_rebuild_queue` | Async rebuild queue with SKIP LOCKED |
| `rm_data_version` | UUID tracking per batch |
| `rm_build_log` | Build observability |
| `rm_facet_config` | Facet hierarchy and whitelist |

### 10. Blog & Content (__blog_*)

| Table | Rows | Purpose |
|---|---|---|
| `__blog_advice` | 85 | Blog advice articles |
| `__blog_advice_h2` | 449 | H2 sections |
| `__blog_advice_h3` | 200 | H3 sections |
| `__blog_advice_cross` | 321 | Cross-links between articles |
| `__blog_guide` | 1 | Repair guides |

### 11. Platform Config (___config*)

| Table | Rows | Purpose |
|---|---|---|
| `___config` | 1 | Main config (23 columns) |
| `___config_admin` | 11 | Admin settings |
| `___config_ip` | 3 | IP whitelist/blacklist |
| `___header_menu` | 6 | Header navigation |
| `___footer_menu` | 13 | Footer navigation |
| `___legal_pages` | 16 | Legal page content |

## Naming Conventions

| Prefix | Meaning |
|---|---|
| `___` (3 underscores) | Legacy e-commerce tables (MySQL migration) |
| `__` (2 underscores) | Feature-specific tables (SEO, diag, blog, RAG, import) |
| `_` (1 underscore) | System tables (killswitch) |
| `auto_*` | Vehicle reference data |
| `pieces_*` | Parts catalog data |
| `kg_*` | Knowledge Graph |
| `rm_*` | Read Model (CQRS) |
| `stg_*` | Staging layer (import) |
| `norm_*` | Normalization layer (import) |
| `xref_*` | Cross-reference layer (import) |
| `v_*` | Views (read-only) |
| `seo_*` | SEO tracking (clicks, impressions) |

## Key Views

| View | Purpose |
|---|---|
| `v_table_health` | Table health monitoring |
| `v_performance_monitoring` | Performance metrics |
| `v_index_usage` | Index usage statistics |
| `v_seo_dashboard_kpis` | SEO KPIs for dashboard |
| `v_seo_blocking_issues` | Critical SEO issues |
| `v_seo_operational_queue` | Priority SEO action queue |
| `v_pipeline_dashboard` | Import pipeline status |
| `v_substitution_funnel` | URL substitution funnel |

## Data Volume Summary

| Domain | Tables | Rows | Size |
|---|---|---|---|
| Parts & compatibility | ~15 | ~400M+ | ~75 GB |
| SEO | ~80+ | ~330K+ | ~1 GB |
| Vehicle reference | ~7 | ~220K+ | ~34 MB |
| E-commerce | ~25 | ~135K+ | ~24 GB (mostly ___xtr_msg) |
| Knowledge Graph | ~20 | ~160+ | ~1 MB |
| Import pipeline | ~20 | 0 (ready) | — |
| Read Model | ~12 | ~5 | ~300 KB |
| Blog/Content | ~10 | ~1K | ~5 MB |
| **Total** | **200+** | **~400M+** | **~100 GB** |
