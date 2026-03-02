#!/bin/bash
# =============================================================================
# validate-architecture.sh
#
# Validates layer dependency rules for the ACNH-wiki iOS project.
#
# Architecture layers (top → bottom):
#   Presentation  → UI layer (ViewControllers, Reactors, Views)
#   Utility       → Shared utilities (can import anything except Presentation)
#   Extension     → Swift extensions (must not import Presentation, CoreDataStorage)
#   CoreDataStorage → Persistence (must not import Presentation, Networking)
#   Networking    → API layer (must not import Presentation, CoreDataStorage, Utility)
#   Models        → Pure domain models (only Foundation / CoreFoundation)
#
# Usage:
#   ./scripts/validate-architecture.sh            # normal mode (allowlist = warnings)
#   ./scripts/validate-architecture.sh --strict    # strict mode (allowlist = errors)
#
# Exit codes:
#   0 = pass (allowlisted warnings are acceptable)
#   1 = new (non-allowlisted) violations found
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
STRICT=false
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=true ;;
        --help|-h)
            echo "Usage: $0 [--strict]"
            echo "  --strict   Treat allowlisted violations as errors (exit 1)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: ${arg}${RESET}" >&2
            exit 2
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Auto-detect SOURCES_DIR relative to this script's location
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCES_DIR="${REPO_ROOT}/Animal-Crossing-Wiki/Projects/App/Sources"

if [[ ! -d "${SOURCES_DIR}" ]]; then
    echo -e "${RED}ERROR: Sources directory not found at ${SOURCES_DIR}${RESET}" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
ERRORS=0
WARNINGS=0

# ---------------------------------------------------------------------------
# Allowlist — known Presentation files that reference CoreData*Storage
# concrete classes as default parameters. These are legacy violations
# scheduled for refactoring.
# ---------------------------------------------------------------------------
ALLOWLIST=(
    "Presentation/Catalog/ViewModels/ItemDetailReactor.swift"
    "Presentation/Catalog/ViewModels/ItemsReactor.swift"
    "Presentation/Catalog/ViewModels/CatalogCellReactor.swift"
    "Presentation/Dashboard/ViewModels/CustomTaskReactor.swift"
    "Presentation/Dashboard/ViewModels/TodaysTasksSectionReactor.swift"
    "Presentation/Dashboard/ViewModels/PreferencesReactor.swift"
    "Presentation/Dashboard/ViewModels/AppSettingReactor.swift"
    "Presentation/Dashboard/ViewModels/TasksEditReactor.swift"
    "Presentation/Animals/ViewModels/VillagerDetailReactor.swift"
    "Presentation/Animals/ViewModels/VillagersCellReactor.swift"
    "Presentation/Animals/ViewModels/NPCDetailReactor.swift"
    "Presentation/Animals/ViewModels/NPCCellReactor.swift"
    "Presentation/Collection/ViewModels/CollectionReactor.swift"
)

# Allowlist — known Utility files that reference Presentation types.
# TurnipPriceCalculator uses TurnipPricesReactor.DayOfWeek/Period enums.
REVERSE_DEP_ALLOWLIST=(
    "Utility/TurnipPriceCalculator.swift"
)

# Helper: check if a relative path (from SOURCES_DIR) is in the allowlist.
# Uses a linear scan — the list is small so this is fine.
is_allowlisted() {
    local rel_path="$1"
    local entry
    for entry in "${ALLOWLIST[@]}"; do
        if [[ "${entry}" == "${rel_path}" ]]; then
            return 0
        fi
    done
    return 1
}

# Helper: check if a relative path is in the reverse dependency allowlist.
is_reverse_dep_allowlisted() {
    local rel_path="$1"
    local entry
    for entry in "${REVERSE_DEP_ALLOWLIST[@]}"; do
        if [[ "${entry}" == "${rel_path}" ]]; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Helper: print section header
# ---------------------------------------------------------------------------
print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
}

# ---------------------------------------------------------------------------
# Helper: record a violation or warning
#   $1 = relative file path
#   $2 = line number
#   $3 = matching line content
#   $4 = description of the rule broken
#   $5 = "allowlisted" or "" (empty)
# ---------------------------------------------------------------------------
report_violation() {
    local file="$1"
    local lineno="$2"
    local content="$3"
    local rule="$4"
    local allowlisted="${5:-}"

    if [[ "${allowlisted}" == "allowlisted" ]] && [[ "${STRICT}" == false ]]; then
        echo -e "  ${YELLOW}[WARN]${RESET} ${file}:${lineno}"
        echo -e "         ${content}"
        echo -e "         ${YELLOW}^ ${rule} (allowlisted)${RESET}"
        ((WARNINGS++)) || true
    else
        echo -e "  ${RED}[ERROR]${RESET} ${file}:${lineno}"
        echo -e "          ${content}"
        echo -e "          ${RED}^ ${rule}${RESET}"
        ((ERRORS++)) || true
    fi
}

# ============================================================================
# CHECK 1: Models purity
#   Models/*.swift may only import Foundation and CoreFoundation.
# ============================================================================
print_header "Check 1: Models purity (only Foundation / CoreFoundation)"

MODELS_DIR="${SOURCES_DIR}/Models"
check1_count=0

if [[ -d "${MODELS_DIR}" ]]; then
    while IFS= read -r swift_file; do
        while IFS=: read -r lineno line; do
            # Extract the imported module name
            module="$(echo "${line}" | sed -E 's/^import[[:space:]]+//' | tr -d '[:space:]')"
            case "${module}" in
                Foundation|CoreFoundation) ;; # allowed
                *)
                    rel_path="${swift_file#"${SOURCES_DIR}/"}"
                    report_violation "${rel_path}" "${lineno}" "${line}" \
                        "Models must only import Foundation or CoreFoundation"
                    ((check1_count++)) || true
                    ;;
            esac
        done < <(grep -n '^import ' "${swift_file}" 2>/dev/null || true)
    done < <(find "${MODELS_DIR}" -name '*.swift' -type f 2>/dev/null | sort)
fi

if [[ ${check1_count} -eq 0 ]]; then
    echo -e "  ${GREEN}No violations found.${RESET}"
fi

# ============================================================================
# CHECK 2: Networking isolation
#   Networking/**/*.swift must NOT reference types from:
#     - Presentation (ViewController, Coordinator, Reactor, View classes)
#     - CoreDataStorage (CoreData*Storage classes)
#     - Utility (Items, HapticManager, MusicPlayerManager, etc.)
# ============================================================================
print_header "Check 2: Networking isolation (no Presentation / CoreDataStorage / Utility)"

NETWORKING_DIR="${SOURCES_DIR}/Networking"
check2_count=0

# Forbidden patterns in Networking: concrete CoreData classes, Presentation types, Utility types
NETWORKING_FORBIDDEN_PATTERNS=(
    'CoreData[A-Z][A-Za-z]*Storage'
    'ViewController'
    'Coordinator'
    'Reactor'
    'Items\.shared'
    'HapticManager'
    'MusicPlayerManager'
    'TurnipPriceCalculator'
    'TurnipPricePredictor'
)

if [[ -d "${NETWORKING_DIR}" ]]; then
    for pattern in "${NETWORKING_FORBIDDEN_PATTERNS[@]}"; do
        while IFS= read -r match_line; do
            # Format: filepath:lineno:content
            file="$(echo "${match_line}" | cut -d: -f1)"
            lineno="$(echo "${match_line}" | cut -d: -f2)"
            content="$(echo "${match_line}" | cut -d: -f3-)"
            rel_path="${file#"${SOURCES_DIR}/"}"

            # Skip comment lines (rough heuristic: line starts with // or *)
            trimmed="$(echo "${content}" | sed 's/^[[:space:]]*//')"
            if [[ "${trimmed}" == //* ]] || [[ "${trimmed}" == \** ]]; then
                continue
            fi

            report_violation "${rel_path}" "${lineno}" "${content}" \
                "Networking must not reference Presentation/CoreDataStorage/Utility types (matched: ${pattern})"
            ((check2_count++)) || true
        done < <(grep -rn -E "${pattern}" "${NETWORKING_DIR}" --include='*.swift' 2>/dev/null || true)
    done
fi

if [[ ${check2_count} -eq 0 ]]; then
    echo -e "  ${GREEN}No violations found.${RESET}"
fi

# ============================================================================
# CHECK 3: Presentation -> CoreDataStorage concrete references
#   Presentation/**/*.swift must NOT directly reference CoreData*Storage
#   concrete implementation classes. Allowlisted files produce warnings.
# ============================================================================
print_header "Check 3: Presentation must not reference CoreData*Storage concrete classes"

PRESENTATION_DIR="${SOURCES_DIR}/Presentation"
check3_count=0

if [[ -d "${PRESENTATION_DIR}" ]]; then
    while IFS= read -r match_line; do
        file="$(echo "${match_line}" | cut -d: -f1)"
        lineno="$(echo "${match_line}" | cut -d: -f2)"
        content="$(echo "${match_line}" | cut -d: -f3-)"
        rel_path="${file#"${SOURCES_DIR}/"}"

        # Skip comment lines
        trimmed="$(echo "${content}" | sed 's/^[[:space:]]*//')"
        if [[ "${trimmed}" == //* ]] || [[ "${trimmed}" == \** ]]; then
            continue
        fi

        if is_allowlisted "${rel_path}"; then
            report_violation "${rel_path}" "${lineno}" "${content}" \
                "Presentation should use protocol abstractions instead of CoreData*Storage concrete classes" \
                "allowlisted"
        else
            report_violation "${rel_path}" "${lineno}" "${content}" \
                "Presentation must not reference CoreData*Storage concrete classes (NEW violation!)"
            ((check3_count++)) || true
        fi
    done < <(grep -rn -E 'CoreData[A-Z][A-Za-z]*Storage' "${PRESENTATION_DIR}" --include='*.swift' 2>/dev/null || true)
fi

if [[ ${check3_count} -eq 0 ]] && [[ ${WARNINGS} -eq 0 ]]; then
    echo -e "  ${GREEN}No violations found.${RESET}"
elif [[ ${check3_count} -eq 0 ]]; then
    echo -e "  ${GREEN}No new violations (${WARNINGS} allowlisted warning(s) above).${RESET}"
fi

# ============================================================================
# CHECK 4: Reverse dependencies — lower layers must not import upper layers
#
#   CoreDataStorage must NOT import: Presentation, Networking
#   Extension must NOT import: Presentation, CoreDataStorage
#   Models must NOT import anything except Foundation/CoreFoundation (covered
#         in Check 1, but we also verify no Presentation/Networking/etc.)
# ============================================================================
print_header "Check 4: Reverse dependencies (lower layers must not import upper layers)"

check4_count=0

# Helper: scan a directory for forbidden patterns in non-comment lines.
#   $1 = directory to scan
#   $2 = grep -E pattern
#   $3 = rule description for error message
scan_for_violations() {
    local scan_dir="$1"
    local pattern="$2"
    local rule_desc="$3"
    local found=0

    if [[ ! -d "${scan_dir}" ]]; then
        return 0
    fi

    while IFS= read -r match_line; do
        local file lineno content trimmed rel_path
        file="$(echo "${match_line}" | cut -d: -f1)"
        lineno="$(echo "${match_line}" | cut -d: -f2)"
        content="$(echo "${match_line}" | cut -d: -f3-)"
        rel_path="${file#"${SOURCES_DIR}/"}"

        # Skip comment lines
        trimmed="$(echo "${content}" | sed 's/^[[:space:]]*//')"
        if [[ "${trimmed}" == //* ]] || [[ "${trimmed}" == \** ]]; then
            continue
        fi

        report_violation "${rel_path}" "${lineno}" "${content}" "${rule_desc}"
        ((found++)) || true
        ((check4_count++)) || true
    done < <(grep -rn -E "${pattern}" "${scan_dir}" --include='*.swift' 2>/dev/null || true)

    return 0
}

# --- CoreDataStorage must not reference Presentation or Networking ---
# We check for:
#   - Project-specific ViewController subclasses (not UIViewController which is UIKit)
#   - Coordinator types from Presentation
#   - Reactor subclasses from Presentation (not ReactorKit which is a framework)
#   - Networking provider/request types
# Pattern: match ViewController not preceded by "UI", plus Coordinator, Reactor (not ReactorKit/Reactive)
COREDATA_DIR="${SOURCES_DIR}/CoreDataStorage"
scan_for_violations "${COREDATA_DIR}" \
    '([^I]ViewController[^+]|[^/a-z]Coordinator|[^a-z]Reactor[^Kit+]|APIRequest|APIProvider|DefaultAPIProvider)' \
    "CoreDataStorage must not reference Presentation or Networking types"

# --- Extension must not reference Presentation or CoreDataStorage ---
# We check for:
#   - CoreData*Storage concrete classes
#   - Project-specific ViewController subclasses (UIViewController is fine - it's UIKit)
#   - Coordinator types from Presentation
# Pattern excludes UIViewController (a UIKit base class legitimately used in extensions)
EXTENSION_DIR="${SOURCES_DIR}/Extension"
scan_for_violations "${EXTENSION_DIR}" \
    'CoreData[A-Z][A-Za-z]*Storage' \
    "Extension must not reference CoreDataStorage concrete classes"

# For Extension ViewController check, we must exclude UIViewController (UIKit framework type).
# Only flag project-specific *ViewController subclass references.
if [[ -d "${EXTENSION_DIR}" ]]; then
    while IFS= read -r match_line; do
        file="$(echo "${match_line}" | cut -d: -f1)"
        lineno="$(echo "${match_line}" | cut -d: -f2)"
        content="$(echo "${match_line}" | cut -d: -f3-)"
        rel_path="${file#"${SOURCES_DIR}/"}"

        # Skip comment lines
        trimmed="$(echo "${content}" | sed 's/^[[:space:]]*//')"
        if [[ "${trimmed}" == //* ]] || [[ "${trimmed}" == \** ]]; then
            continue
        fi

        # Exclude UIKit base types — UIViewController and rootViewController property
        if echo "${content}" | grep -qE 'UIViewController|rootViewController'; then
            continue
        fi

        report_violation "${rel_path}" "${lineno}" "${content}" \
            "Extension must not reference Presentation types (ViewController/Coordinator)"
        ((check4_count++)) || true
    done < <(grep -rn -E '(ViewController|Coordinator)' \
        "${EXTENSION_DIR}" --include='*.swift' 2>/dev/null \
        | grep -v '//.*ViewController\|//.*Coordinator' || true)
fi

# --- Utility must not reference Presentation ---
# Same approach: exclude UIViewController and ReactorKit framework references.
UTILITY_DIR="${SOURCES_DIR}/Utility"
if [[ -d "${UTILITY_DIR}" ]]; then
    while IFS= read -r match_line; do
        file="$(echo "${match_line}" | cut -d: -f1)"
        lineno="$(echo "${match_line}" | cut -d: -f2)"
        content="$(echo "${match_line}" | cut -d: -f3-)"
        rel_path="${file#"${SOURCES_DIR}/"}"

        # Skip comment lines
        trimmed="$(echo "${content}" | sed 's/^[[:space:]]*//')"
        if [[ "${trimmed}" == //* ]] || [[ "${trimmed}" == \** ]]; then
            continue
        fi

        # Exclude UIViewController (UIKit) and ReactorKit (framework)
        if echo "${content}" | grep -qE 'UIViewController|ReactorKit|import Reactor'; then
            continue
        fi

        if is_reverse_dep_allowlisted "${rel_path}"; then
            report_violation "${rel_path}" "${lineno}" "${content}" \
                "Utility should not reference Presentation types" \
                "allowlisted"
        else
            report_violation "${rel_path}" "${lineno}" "${content}" \
                "Utility must not reference Presentation types"
            ((check4_count++)) || true
        fi
    done < <(grep -rn -E '(ViewController|Coordinator|Reactor)' \
        "${UTILITY_DIR}" --include='*.swift' 2>/dev/null \
        | grep -v '//.*ViewController\|//.*Coordinator\|//.*Reactor' || true)
fi

if [[ ${check4_count} -eq 0 ]]; then
    echo -e "  ${GREEN}No violations found.${RESET}"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  SUMMARY${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
echo ""

if [[ "${STRICT}" == true ]]; then
    echo -e "  Mode: ${RED}STRICT${RESET} (allowlisted violations are treated as errors)"
else
    echo -e "  Mode: ${GREEN}NORMAL${RESET} (allowlisted violations are warnings)"
fi

echo ""
echo -e "  Errors:   ${ERRORS}"
echo -e "  Warnings: ${WARNINGS}"
echo ""

if [[ ${ERRORS} -gt 0 ]]; then
    echo -e "  ${RED}${BOLD}FAIL${RESET} ${RED}Architecture validation failed with ${ERRORS} error(s).${RESET}"
    echo ""
    exit 1
else
    if [[ ${WARNINGS} -gt 0 ]]; then
        echo -e "  ${GREEN}${BOLD}PASS${RESET} ${GREEN}Architecture validation passed (${WARNINGS} warning(s) in allowlist).${RESET}"
    else
        echo -e "  ${GREEN}${BOLD}PASS${RESET} ${GREEN}Architecture validation passed with no issues.${RESET}"
    fi
    echo ""
    exit 0
fi
