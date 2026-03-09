#!/usr/bin/env bash
# status-report.sh — AI-COS Ecosystem Status Report
# Generates a comprehensive Markdown (or JSON/text) report of the ecosystem state.
#
# Usage:
#   ./scripts/status-report.sh [--format md|json|text] [--output <file>]
#
# Sources:
#   - health-check.sh (service health)
#   - git log of local repo clones in /opt/aicos/repos/
#   - docs/roadmap.md (task completion progress)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPOS_DIR="${REPOS_DIR:-/opt/aicos/repos}"

FORMAT="md"
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_DISPLAY=$(date -u +"%Y-%m-%d %H:%M UTC")

# Redirect stdout to file if --output is given
if [[ -n "$OUTPUT_FILE" ]]; then
  exec > "$OUTPUT_FILE"
fi

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

# Get last commit info for a repo (prints a Markdown table row)
repo_row() {
  local repo_path="$1"
  local repo_name="$2"
  if [[ ! -d "${repo_path}/.git" ]]; then
    printf "| %s | — | not cloned locally |\n" "$repo_name"
    return
  fi
  local last_commit last_date branch
  last_commit=$(git -C "$repo_path" log -1 --pretty=format:"%h %s" 2>/dev/null || echo "unknown")
  last_date=$(git -C "$repo_path" log -1 --pretty=format:"%cd" --date=short 2>/dev/null || echo "unknown")
  branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  printf "| %s | %s \`%s\` | %s |\n" "$repo_name" "$last_date" "$branch" "$last_commit"
}

# Parse roadmap.md for total [x] vs [ ] counts
roadmap_summary() {
  local roadmap_file="${REPO_ROOT}/docs/roadmap.md"
  [[ ! -f "$roadmap_file" ]] && echo "roadmap not found" && return
  local total_done=0 total_pending=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^\-\ \[x\] ]]; then total_done=$(( total_done + 1 )); fi
    if [[ "$line" =~ ^\-\ \[\ \] ]]; then total_pending=$(( total_pending + 1 )); fi
  done < "$roadmap_file"
  echo "${total_done}/$(( total_done + total_pending )) tasks complete"
}

# Print progress bar for a phase (stdout)
phase_bar() {
  local done="$1" total="$2" label="$3"
  [[ $total -eq 0 ]] && return
  local pct=$(( done * 100 / total ))
  local filled=$(( pct / 10 )) empty=$(( 10 - pct / 10 ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done
  echo "- **${label}**: \`${bar}\` ${done}/${total} (${pct}%)"
}

REPOS=("ai-cos-system" "nestjs-remix-monorepo" "governance-vault" "agent-submissions" "automecanik-rag")

# --------------------------------------------------------------------------- #
# Collect data
# --------------------------------------------------------------------------- #
HEALTH_JSON=""
if [[ -x "${SCRIPT_DIR}/health-check.sh" ]]; then
  HEALTH_JSON=$("${SCRIPT_DIR}/health-check.sh" --json 2>/dev/null || true)
fi

ROADMAP_PROGRESS=$(roadmap_summary)

# --------------------------------------------------------------------------- #
# Build Markdown report
# --------------------------------------------------------------------------- #
build_md() {
  echo "# AI-COS Ecosystem Status Report"
  echo ""
  echo "> Generated: ${DATE_DISPLAY} | Zone: aicos_vps (178.104.1.118) | READ-ONLY observatoire"
  echo ""

  # --- Service Health ---
  echo "## Service Health"
  echo ""
  if [[ -n "$HEALTH_JSON" ]] && command -v python3 &>/dev/null; then
    local tmp_health
    tmp_health=$(mktemp /tmp/aicos-health-XXXXXX.json)
    echo "$HEALTH_JSON" > "$tmp_health"
    python3 - "$tmp_health" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    services = data.get('services', {})
    summary = data.get('summary', {})
    icons = {'OK': '🟢', 'WARN': '🟡', 'ERROR': '🔴', 'SKIP': '⚪'}
    print('| Service | Status | Detail |')
    print('|---------|--------|--------|')
    for name, info in services.items():
        status = info.get('status', 'SKIP')
        msg = info.get('message', '')
        icon = icons.get(status, '⚪')
        print(f'| {name} | {icon} {status} | {msg} |')
    print()
    print(f'**Summary:** 🟢 {summary.get("ok",0)} OK | 🟡 {summary.get("warn",0)} WARN | 🔴 {summary.get("error",0)} ERROR | ⚪ {summary.get("skip",0)} SKIP')
except Exception as e:
    print(f'> Health check data unavailable: {e}')
PYEOF
    rm -f "$tmp_health"
  else
    echo "> Health check data unavailable (run health-check.sh separately)"
  fi
  echo ""

  # --- Repos ---
  echo "## Repository State"
  echo ""
  echo "| Repository | Last Commit | Message |"
  echo "|------------|-------------|---------|"
  for repo in "${REPOS[@]}"; do
    repo_row "${REPOS_DIR}/${repo}" "$repo"
  done
  echo ""

  # --- Roadmap ---
  echo "## Roadmap Progress"
  echo ""
  echo "**File:** \`docs/roadmap.md\`"
  echo ""

  local roadmap_file="${REPO_ROOT}/docs/roadmap.md"
  if [[ -f "$roadmap_file" ]]; then
    local phase="" phase_done=0 phase_total=0
    while IFS= read -r line; do
      if [[ "$line" =~ ^##\ Phase ]]; then
        if [[ -n "$phase" ]]; then
          phase_bar "$phase_done" "$phase_total" "$phase"
          phase_done=0 phase_total=0
        fi
        phase=$(echo "$line" | sed 's/^## //')
      fi
      if [[ "$line" =~ ^\-\ \[x\] ]]; then phase_done=$(( phase_done + 1 )); phase_total=$(( phase_total + 1 )); fi
      if [[ "$line" =~ ^\-\ \[\ \] ]]; then phase_total=$(( phase_total + 1 )); fi
    done < "$roadmap_file"
    # Last phase
    if [[ -n "$phase" && $phase_total -gt 0 ]]; then
      phase_bar "$phase_done" "$phase_total" "$phase"
    fi
  else
    echo "> roadmap.md not found"
  fi
  echo ""
  echo "**Overall:** ${ROADMAP_PROGRESS}"
  echo ""

  # --- Summary ---
  echo "## Summary"
  echo ""
  echo "| Dimension | Value |"
  echo "|-----------|-------|"
  echo "| Report date | ${DATE_DISPLAY} |"
  echo "| Roadmap progress | ${ROADMAP_PROGRESS} |"
  local repo_count
  repo_count=$(ls -d "${REPOS_DIR}"/*/  2>/dev/null | wc -l | tr -d ' ')
  echo "| Repos cloned locally | ${repo_count} |"
  echo "| AI-COS zone | aicos_vps READ-ONLY (ADR-012) |"
  echo ""
  echo "---"
  echo "*Generated by \`scripts/status-report.sh\` — ai-cos-system*"
}

# --------------------------------------------------------------------------- #
# Build JSON report
# --------------------------------------------------------------------------- #
build_json() {
  echo "{"
  echo "  \"timestamp\": \"${TIMESTAMP}\","
  echo "  \"zone\": \"aicos_vps\","
  echo "  \"roadmap_progress\": \"${ROADMAP_PROGRESS}\","
  if [[ -n "$HEALTH_JSON" ]]; then
    printf '  "health": %s,\n' "$HEALTH_JSON"
  fi
  echo "  \"repos\": {"
  local first=true
  for repo in "${REPOS[@]}"; do
    [[ "$first" == false ]] && echo ","
    first=false
    local repo_path="${REPOS_DIR}/${repo}"
    if [[ -d "${repo_path}/.git" ]]; then
      local last_hash branch
      last_hash=$(git -C "$repo_path" log -1 --pretty=format:"%h" 2>/dev/null || echo "unknown")
      branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      printf '    "%s": { "branch": "%s", "last_commit": "%s" }' "$repo" "$branch" "$last_hash"
    else
      printf '    "%s": { "status": "not_cloned" }' "$repo"
    fi
  done
  echo ""
  echo "  }"
  echo "}"
}

# --------------------------------------------------------------------------- #
# Build text report
# --------------------------------------------------------------------------- #
build_text() {
  echo "AI-COS Ecosystem Status — ${DATE_DISPLAY}"
  echo "=================================================="
  echo "Roadmap : ${ROADMAP_PROGRESS}"
  echo ""
  echo "Repos:"
  for repo in "${REPOS[@]}"; do
    local repo_path="${REPOS_DIR}/${repo}"
    if [[ -d "${repo_path}/.git" ]]; then
      local last branch
      last=$(git -C "$repo_path" log -1 --pretty=format:"%h %s" 2>/dev/null || echo "unknown")
      branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      printf "  %-30s [%s] %s\n" "$repo" "$branch" "$last"
    else
      printf "  %-30s not cloned\n" "$repo"
    fi
  done
}

# --------------------------------------------------------------------------- #
# Generate output
# --------------------------------------------------------------------------- #
case "$FORMAT" in
  md)   build_md ;;
  json) build_json ;;
  text) build_text ;;
  *)    echo "Unknown format: $FORMAT (use md, json, or text)" >&2; exit 1 ;;
esac

if [[ -n "$OUTPUT_FILE" ]]; then
  echo "Report written to: $OUTPUT_FILE" >&2
fi
