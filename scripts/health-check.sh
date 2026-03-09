#!/usr/bin/env bash
# health-check.sh — AI-COS Ecosystem Health Check
# Checks all subsystem health endpoints from the AI-COS observatoire (READ-ONLY)
#
# Usage:
#   ./scripts/health-check.sh [--json] [--timeout <sec>] [--dry-run]
#
# Environment variables (override defaults):
#   PLATFORM_URL      — NestJS PROD base URL       (default: https://automecanik.com)
#   RAG_SERVICE_URL   — RAG FastAPI base URL        (default: http://localhost:8000)
#   WEAVIATE_URL      — Weaviate base URL           (default: http://localhost:8080)
#   SUPABASE_URL      — Supabase project URL        (default: https://cxpojprgwgubzjyqzmoq.supabase.co)
#   SUPABASE_ANON_KEY — Supabase anon/service key   (default: empty — check skipped if unset)
#   GITHUB_ORG        — GitHub org to check         (default: ak125)

set -euo pipefail

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
PLATFORM_URL="${PLATFORM_URL:-https://automecanik.com}"
RAG_SERVICE_URL="${RAG_SERVICE_URL:-}"
WEAVIATE_URL="${WEAVIATE_URL:-}"
SUPABASE_URL="${SUPABASE_URL:-https://cxpojprgwgubzjyqzmoq.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
GITHUB_ORG="${GITHUB_ORG:-ak125}"
TIMEOUT="${TIMEOUT:-10}"

# --------------------------------------------------------------------------- #
# Flags
# --------------------------------------------------------------------------- #
JSON_OUTPUT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)       JSON_OUTPUT=true; shift ;;
    --timeout)    TIMEOUT="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --------------------------------------------------------------------------- #
# Colors (disabled in JSON mode or non-TTY)
# --------------------------------------------------------------------------- #
if [[ "$JSON_OUTPUT" == false ]] && [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
declare -A RESULTS
declare -A MESSAGES

log() { [[ "$JSON_OUTPUT" == false ]] && echo -e "$*" || true; }

check_http() {
  local name="$1"
  local url="$2"
  local expected_status="${3:-200}"
  local -a extra_headers=()
  if [[ $# -gt 3 ]]; then
    extra_headers=("${@:4}")
  fi

  if [[ "$DRY_RUN" == true ]]; then
    RESULTS["$name"]="SKIP"
    MESSAGES["$name"]="dry-run — would check: $url"
    return
  fi

  local http_code
  local -a curl_args=(-s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT")

  for header in "${extra_headers[@]+"${extra_headers[@]}"}"; do
    [[ -n "$header" ]] && curl_args+=(-H "$header")
  done

  http_code=$(curl "${curl_args[@]}" "$url" 2>/dev/null || echo "000")

  if [[ "$http_code" == "$expected_status" ]]; then
    RESULTS["$name"]="OK"
    MESSAGES["$name"]="HTTP $http_code"
  elif [[ "$http_code" == "000" ]]; then
    RESULTS["$name"]="ERROR"
    MESSAGES["$name"]="unreachable (connection failed)"
  else
    RESULTS["$name"]="WARN"
    MESSAGES["$name"]="HTTP $http_code (expected $expected_status)"
  fi
}

print_service() {
  local name="$1"
  local status="${RESULTS[$name]:-SKIP}"
  local msg="${MESSAGES[$name]:-}"
  local icon

  case "$status" in
    OK)    icon="${GREEN}OK   ${RESET}" ;;
    WARN)  icon="${YELLOW}WARN ${RESET}" ;;
    ERROR) icon="${RED}ERROR${RESET}" ;;
    SKIP)  icon="${CYAN}SKIP ${RESET}" ;;
    *)     icon="     " ;;
  esac

  printf "  %b  %-30s %s\n" "$icon" "$name" "$msg"
}

# --------------------------------------------------------------------------- #
# Checks
# --------------------------------------------------------------------------- #

# 1. NestJS PROD
check_http "NestJS PROD" "${PLATFORM_URL}/api/health"

# 2. RAG FastAPI (optional — skipped if URL not set)
if [[ -n "$RAG_SERVICE_URL" ]]; then
  check_http "RAG FastAPI" "${RAG_SERVICE_URL}/health"
else
  RESULTS["RAG FastAPI"]="SKIP"
  MESSAGES["RAG FastAPI"]="RAG_SERVICE_URL not configured"
fi

# 3. Weaviate (optional — skipped if URL not set)
if [[ -n "$WEAVIATE_URL" ]]; then
  check_http "Weaviate" "${WEAVIATE_URL}/v1/.well-known/ready"
else
  RESULTS["Weaviate"]="SKIP"
  MESSAGES["Weaviate"]="WEAVIATE_URL not configured"
fi

# 4. Supabase REST API
if [[ -n "$SUPABASE_ANON_KEY" ]]; then
  check_http "Supabase" "${SUPABASE_URL}/rest/v1/" "200" "apikey: ${SUPABASE_ANON_KEY}"
else
  RESULTS["Supabase"]="SKIP"
  MESSAGES["Supabase"]="SUPABASE_ANON_KEY not configured"
fi

# 5. GitHub API
check_http "GitHub (org)" "https://api.github.com/orgs/${GITHUB_ORG}"

# --------------------------------------------------------------------------- #
# Output
# --------------------------------------------------------------------------- #
SERVICES=("NestJS PROD" "RAG FastAPI" "Weaviate" "Supabase" "GitHub (org)")

count_ok=0; count_warn=0; count_error=0; count_skip=0
for svc in "${SERVICES[@]}"; do
  case "${RESULTS[$svc]:-SKIP}" in
    OK)    count_ok=$(( count_ok + 1 )) ;;
    WARN)  count_warn=$(( count_warn + 1 )) ;;
    ERROR) count_error=$(( count_error + 1 )) ;;
    SKIP)  count_skip=$(( count_skip + 1 )) ;;
  esac
done

if [[ "$JSON_OUTPUT" == true ]]; then
  echo "{"
  echo "  \"timestamp\": \"${TIMESTAMP}\","
  echo "  \"summary\": { \"ok\": ${count_ok}, \"warn\": ${count_warn}, \"error\": ${count_error}, \"skip\": ${count_skip} },"
  echo "  \"services\": {"
  first=true
  for svc in "${SERVICES[@]}"; do
    [[ "$first" == false ]] && echo ","
    first=false
    printf '    "%s": { "status": "%s", "message": "%s" }' \
      "$svc" "${RESULTS[$svc]:-SKIP}" "${MESSAGES[$svc]:-}"
  done
  echo ""
  echo "  }"
  echo "}"
else
  log ""
  log "${BOLD}AI-COS Ecosystem Health Check${RESET} — ${TIMESTAMP}"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for svc in "${SERVICES[@]}"; do
    print_service "$svc"
  done
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Summary: ${GREEN}${count_ok} OK${RESET} | ${YELLOW}${count_warn} WARN${RESET} | ${RED}${count_error} ERROR${RESET} | ${CYAN}${count_skip} SKIP${RESET}"
  log ""
fi

# Exit code: 0 = all OK/SKIP, 1 = any WARN, 2 = any ERROR
if [[ $count_error -gt 0 ]]; then exit 2; fi
if [[ $count_warn -gt 0 ]]; then exit 1; fi
exit 0
