#!/bin/bash
# =============================================================================
# validate-docs.sh
#
# Validates that file path references in docs/ are still valid.
# Catches stale references when code is refactored or files are moved.
#
# Two types of references are checked:
#   Type A: Source code paths (*.swift files referenced in docs)
#   Type B: Doc cross-references (relative links between .md files)
#
# Usage:
#   ./scripts/validate-docs.sh
#
# Exit codes:
#   0 = all references valid
#   1 = broken references found
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# Auto-detect paths relative to script location
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCS_DIR="${REPO_ROOT}/docs"
SOURCES_DIR="${REPO_ROOT}/Animal-Crossing-Wiki/Projects/App/Sources"

if [[ ! -d "${DOCS_DIR}" ]]; then
    echo -e "${RED}ERROR: Docs directory not found at ${DOCS_DIR}${RESET}" >&2
    exit 2
fi

if [[ ! -d "${SOURCES_DIR}" ]]; then
    echo -e "${RED}ERROR: Sources directory not found at ${SOURCES_DIR}${RESET}" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Top-level source layer directories (used for fuzzy path resolution)
# When a backtick path like `Items/Item.swift` doesn't resolve directly,
# we try prepending each layer prefix to find it (e.g., Models/Items/Item.swift).
# ---------------------------------------------------------------------------
SOURCE_LAYERS=(
    "Models"
    "Networking"
    "CoreDataStorage"
    "Utility"
    "Extension"
    "Presentation"
)

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
TOTAL=0
BROKEN=0

# ---------------------------------------------------------------------------
# Deduplication via temp file (compatible with bash 3.2)
# ---------------------------------------------------------------------------
SEEN_FILE="$(mktemp)"
trap 'rm -f "${SEEN_FILE}"' EXIT

# Check if a key has been seen before. Returns 0 if already seen, 1 if new.
is_seen() {
    if grep -qxF "$1" "${SEEN_FILE}" 2>/dev/null; then
        return 0
    fi
    echo "$1" >> "${SEEN_FILE}"
    return 1
}

# ---------------------------------------------------------------------------
# Helper: check if a path is a template/placeholder (not a real file ref)
# Returns 0 if the path should be skipped, 1 if it's a real reference.
# ---------------------------------------------------------------------------
is_template_path() {
    local path="$1"

    # Skip paths with template placeholders: {Feature}, {xxx}
    if [[ "${path}" == *"{"* ]]; then
        return 0
    fi

    # Skip paths with placeholder names: Xxx (common in guide docs)
    if [[ "${path}" == *"Xxx"* ]]; then
        return 0
    fi

    # Skip glob patterns: *.swift, Models/*.swift
    if [[ "${path}" == *"*"* ]]; then
        return 0
    fi

    return 1
}

# ---------------------------------------------------------------------------
# Helper: print section header
# ---------------------------------------------------------------------------
print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}=======================================================================${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}=======================================================================${RESET}"
}

# ---------------------------------------------------------------------------
# Helper: report a reference check result
#   $1 = doc file (relative to REPO_ROOT)
#   $2 = referenced path
#   $3 = "PASS" or "FAIL"
#   $4 = (optional) extra info
# ---------------------------------------------------------------------------
report_ref() {
    local doc_file="$1"
    local ref_path="$2"
    local status="$3"
    local info="${4:-}"

    TOTAL=$((TOTAL + 1))

    if [[ "${status}" == "PASS" ]]; then
        echo -e "  ${GREEN}[PASS]${RESET} ${doc_file}  ->  ${ref_path}"
    else
        echo -e "  ${RED}[FAIL]${RESET} ${doc_file}  ->  ${ref_path}"
        if [[ -n "${info}" ]]; then
            echo -e "         ${RED}^ ${info}${RESET}"
        fi
        BROKEN=$((BROKEN + 1))
    fi
}

# ---------------------------------------------------------------------------
# Helper: strip code fence blocks from a file.
# Outputs the file contents with lines inside ``` blocks replaced by empty
# lines (preserving line count for accurate reference, but removing content
# so we don't match example paths inside code fences).
# ---------------------------------------------------------------------------
strip_code_fences() {
    local file="$1"
    awk '
        /^```/ {
            in_fence = !in_fence
            print ""
            next
        }
        in_fence { print ""; next }
        { print }
    ' "${file}"
}

# ---------------------------------------------------------------------------
# Helper: normalize a path by resolving ".." components.
# Pure bash, no external dependencies. Works with bash 3.2.
# ---------------------------------------------------------------------------
normalize_path() {
    local path="$1"
    local result=""
    local IFS='/'
    local parts
    read -ra parts <<< "${path}"

    local stack=()
    local part
    for part in "${parts[@]}"; do
        if [[ "${part}" == ".." ]]; then
            if [[ ${#stack[@]} -gt 0 ]]; then
                unset 'stack[${#stack[@]}-1]'
            fi
        elif [[ "${part}" != "." ]] && [[ -n "${part}" ]]; then
            stack+=("${part}")
        fi
    done

    result=""
    for part in "${stack[@]}"; do
        if [[ -n "${result}" ]]; then
            result="${result}/${part}"
        else
            result="${part}"
        fi
    done
    echo "${result}"
}

# ---------------------------------------------------------------------------
# Helper: try to resolve a .swift path reference.
# Attempts multiple resolution strategies:
#   1. Direct path under SOURCES_DIR
#   2. Strip common prefixes (Projects/App/Sources/, Sources/) then under SOURCES_DIR
#   3. Try prepending each source layer prefix (Models/, Networking/, etc.)
#   4. Check from REPO_ROOT (for non-source files like Tuist/Package.swift)
#   5. Check from REPO_ROOT under Animal-Crossing-Wiki/ prefix
#
# Returns 0 (found) or 1 (not found).
# ---------------------------------------------------------------------------
resolve_swift_path() {
    local ref_path="$1"

    # Strategy 1: Direct under SOURCES_DIR
    if [[ -f "${SOURCES_DIR}/${ref_path}" ]]; then
        return 0
    fi

    # Strategy 2: Strip common prefixes
    local normalized="${ref_path}"
    normalized="${normalized#Projects/App/Sources/}"
    normalized="${normalized#Sources/}"
    if [[ -f "${SOURCES_DIR}/${normalized}" ]]; then
        return 0
    fi

    # Strategy 3: Try prepending each source layer prefix
    local layer
    for layer in "${SOURCE_LAYERS[@]}"; do
        if [[ -f "${SOURCES_DIR}/${layer}/${normalized}" ]]; then
            return 0
        fi
    done

    # Strategy 4: Check from REPO_ROOT (for files like Tuist/Package.swift)
    if [[ -f "${REPO_ROOT}/${ref_path}" ]]; then
        return 0
    fi

    # Strategy 5: Check from REPO_ROOT under Animal-Crossing-Wiki/
    if [[ -f "${REPO_ROOT}/Animal-Crossing-Wiki/${ref_path}" ]]; then
        return 0
    fi

    return 1
}

# ---------------------------------------------------------------------------
# Collect all .md files under docs/
# ---------------------------------------------------------------------------
MD_FILES=()
while IFS= read -r f; do
    MD_FILES+=("${f}")
done < <(find "${DOCS_DIR}" -name '*.md' -type f 2>/dev/null | sort)

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No .md files found under ${DOCS_DIR}${RESET}"
    exit 0
fi

# ==========================================================================
# TYPE A: Source code path references
#
# We look for two patterns (outside code fences):
#   1. Markdown links pointing to .swift files:  [text](path/to/File.swift)
#   2. Backtick-quoted paths ending in .swift:    `path/to/File.swift`
#
# We resolve these paths using multiple strategies (see resolve_swift_path).
# Template/placeholder paths ({Feature}, Xxx, globs) are skipped.
# ==========================================================================
print_header "Type A: Source code path references (*.swift)"

for md_file in "${MD_FILES[@]}"; do
    rel_doc="${md_file#"${REPO_ROOT}/"}"
    stripped_content="$(strip_code_fences "${md_file}")"

    # --- Pattern 1: Markdown links to .swift files ---
    # Match [text](path.swift) but NOT [text](http...) or [text](https...)
    while IFS= read -r match; do
        [[ -z "${match}" ]] && continue

        # Extract the path from the markdown link: [text](PATH)
        ref_path="$(echo "${match}" | sed -E 's/.*\]\(([^)]+\.swift)\).*/\1/')"
        [[ -z "${ref_path}" ]] && continue

        # Skip URLs
        if [[ "${ref_path}" =~ ^https?:// ]]; then
            continue
        fi

        # Skip template/placeholder paths
        if is_template_path "${ref_path}"; then
            continue
        fi

        # Deduplicate
        if is_seen "A::${rel_doc}::${ref_path}"; then
            continue
        fi

        # Check existence using multi-strategy resolution
        if resolve_swift_path "${ref_path}"; then
            report_ref "${rel_doc}" "${ref_path}" "PASS"
        else
            report_ref "${rel_doc}" "${ref_path}" "FAIL" "File not found"
        fi

    done < <(echo "${stripped_content}" | grep -oE '\[[^]]*\]\([^)]+\.swift\)' 2>/dev/null || true)

    # --- Pattern 2: Backtick paths ending in .swift ---
    # Match `path/to/File.swift` (must contain at least one slash to be a path)
    while IFS= read -r match; do
        [[ -z "${match}" ]] && continue

        # Extract the path between backticks
        ref_path="$(echo "${match}" | sed -E 's/^`(.*)`$/\1/')"
        [[ -z "${ref_path}" ]] && continue

        # Must contain a slash to be a file path (skip bare type names like `Item.swift`)
        if [[ "${ref_path}" != */* ]]; then
            continue
        fi

        # Skip URLs
        if [[ "${ref_path}" =~ ^https?:// ]]; then
            continue
        fi

        # Skip template/placeholder paths
        if is_template_path "${ref_path}"; then
            continue
        fi

        # Deduplicate
        if is_seen "A::${rel_doc}::${ref_path}"; then
            continue
        fi

        # Check existence using multi-strategy resolution
        if resolve_swift_path "${ref_path}"; then
            report_ref "${rel_doc}" "${ref_path}" "PASS"
        else
            report_ref "${rel_doc}" "${ref_path}" "FAIL" "File not found"
        fi

    done < <(echo "${stripped_content}" | grep -oE '`[^`]+\.swift`' 2>/dev/null || true)
done

# ==========================================================================
# TYPE B: Doc cross-references
#
# We look for markdown links to .md files:  [text](relative/path.md)
# These are resolved relative to the directory containing the doc file.
# We skip URLs and anchor-only links (#section).
# ==========================================================================
print_header "Type B: Doc cross-references (*.md links)"

for md_file in "${MD_FILES[@]}"; do
    rel_doc="${md_file#"${REPO_ROOT}/"}"
    doc_dir="$(dirname "${md_file}")"
    stripped_content="$(strip_code_fences "${md_file}")"

    while IFS= read -r match; do
        [[ -z "${match}" ]] && continue

        # Extract the path from the markdown link
        ref_path="$(echo "${match}" | sed -E 's/.*\]\(([^)]+)\).*/\1/')"
        [[ -z "${ref_path}" ]] && continue

        # Skip URLs
        if [[ "${ref_path}" =~ ^https?:// ]]; then
            continue
        fi

        # Skip anchor-only links
        if [[ "${ref_path}" =~ ^# ]]; then
            continue
        fi

        # Strip anchor fragments (e.g., "gotchas.md#2" -> "gotchas.md")
        ref_path_no_anchor="${ref_path%%#*}"

        # Only check .md references
        if [[ "${ref_path_no_anchor}" != *.md ]]; then
            continue
        fi

        # Deduplicate
        if is_seen "B::${rel_doc}::${ref_path_no_anchor}"; then
            continue
        fi

        # Resolve the path relative to the doc file's directory.
        # If it starts with "docs/", resolve from REPO_ROOT instead.
        if [[ "${ref_path_no_anchor}" == docs/* ]]; then
            resolved="${REPO_ROOT}/${ref_path_no_anchor}"
        else
            # Combine doc_dir + relative path, then normalize away ".." components
            combined="${doc_dir}/${ref_path_no_anchor}"
            resolved="$(normalize_path "${combined}")"
            # normalize_path strips leading slash; re-add it since doc_dir is absolute
            if [[ "${combined}" == /* ]]; then
                resolved="/${resolved}"
            fi
        fi

        if [[ -f "${resolved}" ]]; then
            report_ref "${rel_doc}" "${ref_path}" "PASS"
        else
            report_ref "${rel_doc}" "${ref_path}" "FAIL" "Target doc not found: ${resolved#"${REPO_ROOT}/"}"
        fi

    done < <(echo "${stripped_content}" | grep -oE '\[[^]]*\]\([^)]+\)' 2>/dev/null || true)
done

# ==========================================================================
# SUMMARY
# ==========================================================================
echo ""
echo -e "${BOLD}=======================================================================${RESET}"
echo -e "${BOLD}  SUMMARY${RESET}"
echo -e "${BOLD}=======================================================================${RESET}"
echo ""
echo -e "  References checked: ${TOTAL}"
echo -e "  Broken:             ${BROKEN}"
echo ""

if [[ ${BROKEN} -gt 0 ]]; then
    echo -e "  ${RED}${BOLD}FAIL${RESET} ${RED}Doc validation failed: ${BROKEN} broken reference(s) found.${RESET}"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}${BOLD}PASS${RESET} ${GREEN}All ${TOTAL} reference(s) are valid.${RESET}"
    echo ""
    exit 0
fi
