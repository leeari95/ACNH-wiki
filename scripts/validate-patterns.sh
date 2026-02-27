#!/bin/bash
# ==============================================================================
# validate-patterns.sh
#
# Validates that the Presentation layer follows the project's architectural
# conventions: ReactorKit patterns, Coordinator Route enums, directory
# structure, and ViewController bind(to:) methods.
#
# Usage:  ./scripts/validate-patterns.sh
# Exit:   0 = all checks pass (warnings are OK), 1 = violations found
# ==============================================================================
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
# Auto-detect PRESENTATION_DIR relative to script location
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PRESENTATION_DIR="${REPO_ROOT}/Animal-Crossing-Wiki/Projects/App/Sources/Presentation"
SOURCES_DIR="${REPO_ROOT}/Animal-Crossing-Wiki/Projects/App/Sources"

if [[ ! -d "${PRESENTATION_DIR}" ]]; then
    echo -e "${RED}ERROR: Presentation directory not found at:${RESET}"
    echo "  ${PRESENTATION_DIR}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
VIOLATIONS=0
WARNINGS=0
CHECKS=0

# ---------------------------------------------------------------------------
# Helper: report a violation (increments VIOLATIONS)
# ---------------------------------------------------------------------------
violation() {
    echo -e "  ${RED}FAIL${RESET} $1"
    VIOLATIONS=$((VIOLATIONS + 1))
}

# ---------------------------------------------------------------------------
# Helper: report a warning (increments WARNINGS, does NOT fail the build)
# ---------------------------------------------------------------------------
warn() {
    echo -e "  ${YELLOW}WARN${RESET} $1"
    WARNINGS=$((WARNINGS + 1))
}

# ---------------------------------------------------------------------------
# Helper: report a pass
# ---------------------------------------------------------------------------
pass() {
    echo -e "  ${GREEN}PASS${RESET} $1"
}

# ==============================================================================
# CHECK 1: Reactor Pattern Compliance
#
# Every *Reactor.swift file must contain:
#   - enum Action
#   - enum Mutation
#   - struct State
# ==============================================================================
echo ""
echo -e "${CYAN}${BOLD}[Check 1] Reactor Pattern Compliance${RESET}"
echo -e "${CYAN}──────────────────────────────────────${RESET}"

REACTOR_FILES=$(find "${PRESENTATION_DIR}" -name "*Reactor.swift" -type f | sort)
REACTOR_COUNT=0
REACTOR_VIOLATIONS=0

if [[ -z "${REACTOR_FILES}" ]]; then
    warn "No Reactor files found in Presentation/"
else
    while IFS= read -r file; do
        REACTOR_COUNT=$((REACTOR_COUNT + 1))
        RELATIVE="${file#"${REPO_ROOT}"/}"
        MISSING=""

        if ! grep -q 'enum Action' "$file"; then
            MISSING="${MISSING} enum Action,"
        fi
        if ! grep -q 'enum Mutation' "$file"; then
            MISSING="${MISSING} enum Mutation,"
        fi
        if ! grep -q 'struct State' "$file"; then
            MISSING="${MISSING} struct State,"
        fi

        if [[ -n "${MISSING}" ]]; then
            # Remove trailing comma
            MISSING="${MISSING%,}"
            violation "${RELATIVE} — missing:${MISSING}"
            REACTOR_VIOLATIONS=$((REACTOR_VIOLATIONS + 1))
        else
            pass "${RELATIVE}"
        fi
    done <<< "${REACTOR_FILES}"
fi

CHECKS=$((CHECKS + 1))
echo ""
echo -e "  Scanned ${BOLD}${REACTOR_COUNT}${RESET} Reactor file(s), ${RED}${REACTOR_VIOLATIONS} violation(s)${RESET}"

# ==============================================================================
# CHECK 2: Coordinator Route Enum
#
# Every *Coordinator.swift in Presentation/ must contain: enum Route
# AppCoordinator.swift (in Sources/ root) is excluded.
# ==============================================================================
echo ""
echo -e "${CYAN}${BOLD}[Check 2] Coordinator Route Enum${RESET}"
echo -e "${CYAN}──────────────────────────────────${RESET}"

COORDINATOR_FILES=$(find "${PRESENTATION_DIR}" -name "*Coordinator.swift" -type f | sort)
COORD_COUNT=0
COORD_VIOLATIONS=0

if [[ -z "${COORDINATOR_FILES}" ]]; then
    warn "No Coordinator files found in Presentation/"
else
    while IFS= read -r file; do
        BASENAME="$(basename "$file")"

        # Exclude AppCoordinator.swift (should only be in Sources/ root,
        # but guard against accidental placement in Presentation/ too)
        if [[ "${BASENAME}" == "AppCoordinator.swift" ]]; then
            echo -e "  ${YELLOW}SKIP${RESET} ${file#"${REPO_ROOT}"/} (AppCoordinator excluded)"
            continue
        fi

        COORD_COUNT=$((COORD_COUNT + 1))
        RELATIVE="${file#"${REPO_ROOT}"/}"

        if ! grep -q 'enum Route' "$file"; then
            violation "${RELATIVE} — missing: enum Route"
            COORD_VIOLATIONS=$((COORD_VIOLATIONS + 1))
        else
            pass "${RELATIVE}"
        fi
    done <<< "${COORDINATOR_FILES}"
fi

CHECKS=$((CHECKS + 1))
echo ""
echo -e "  Scanned ${BOLD}${COORD_COUNT}${RESET} Coordinator file(s), ${RED}${COORD_VIOLATIONS} violation(s)${RESET}"

# ==============================================================================
# CHECK 3: Directory Structure
#
# Each feature directory under Presentation/ should contain:
#   Coordinator/, ViewControllers/, ViewModels/
#
# Allowlisted exceptions (warn only, do not fail):
#   - TurnipPrices  : flat structure, no subdirectories expected
#   - MusicPlayer   : no Coordinator/ directory expected
# ==============================================================================
echo ""
echo -e "${CYAN}${BOLD}[Check 3] Feature Directory Structure${RESET}"
echo -e "${CYAN}──────────────────────────────────────${RESET}"

REQUIRED_DIRS=("Coordinator" "ViewControllers" "ViewModels")
STRUCT_VIOLATIONS=0

for feature_path in "${PRESENTATION_DIR}"/*/; do
    FEATURE="$(basename "${feature_path}")"

    # --- TurnipPrices: flat structure, all subdirs are optional (warn only) ---
    if [[ "${FEATURE}" == "TurnipPrices" ]]; then
        FLAT_MISSING=""
        for dir in "${REQUIRED_DIRS[@]}"; do
            if [[ ! -d "${feature_path}${dir}" ]]; then
                FLAT_MISSING="${FLAT_MISSING} ${dir}/,"
            fi
        done
        if [[ -n "${FLAT_MISSING}" ]]; then
            FLAT_MISSING="${FLAT_MISSING%,}"
            warn "${FEATURE}/ — flat structure allowlisted, missing:${FLAT_MISSING}"
        else
            pass "${FEATURE}/ (all subdirectories present)"
        fi
        continue
    fi

    # --- MusicPlayer: Coordinator/ is optional (warn only), rest required ---
    if [[ "${FEATURE}" == "MusicPlayer" ]]; then
        MP_FAIL=0
        for dir in "${REQUIRED_DIRS[@]}"; do
            if [[ ! -d "${feature_path}${dir}" ]]; then
                if [[ "${dir}" == "Coordinator" ]]; then
                    warn "${FEATURE}/ — no Coordinator/ (managed by AppCoordinator, allowlisted)"
                else
                    violation "${FEATURE}/ — missing required directory: ${dir}/"
                    MP_FAIL=$((MP_FAIL + 1))
                fi
            fi
        done
        if [[ ${MP_FAIL} -eq 0 ]]; then
            # Report the non-Coordinator dirs as passing
            for dir in "ViewControllers" "ViewModels"; do
                if [[ -d "${feature_path}${dir}" ]]; then
                    pass "${FEATURE}/${dir}/"
                fi
            done
        fi
        STRUCT_VIOLATIONS=$((STRUCT_VIOLATIONS + MP_FAIL))
        continue
    fi

    # --- Standard features: all subdirectories required ---
    FEAT_FAIL=0
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "${feature_path}${dir}" ]]; then
            violation "${FEATURE}/ — missing required directory: ${dir}/"
            FEAT_FAIL=$((FEAT_FAIL + 1))
        else
            pass "${FEATURE}/${dir}/"
        fi
    done
    STRUCT_VIOLATIONS=$((STRUCT_VIOLATIONS + FEAT_FAIL))
done

CHECKS=$((CHECKS + 1))
echo ""
echo -e "  ${RED}${STRUCT_VIOLATIONS} violation(s)${RESET}"

# ==============================================================================
# CHECK 4: ViewController bind(to:) Pattern
#
# Every *ViewController.swift in Presentation/ must contain: func bind(to
#
# Allowlisted exceptions (warn only, do not fail):
#   - IconChooserViewController.swift    : UI-only, no Reactor
#   - TurnipPriceResultViewController.swift : UI-only, no Reactor
# ==============================================================================
echo ""
echo -e "${CYAN}${BOLD}[Check 4] ViewController bind(to:) Pattern${RESET}"
echo -e "${CYAN}────────────────────────────────────────────${RESET}"

# ViewControllers that intentionally don't use ReactorKit bind(to:) pattern
BIND_ALLOWLIST=(
    "IconChooserViewController.swift"
    "TurnipPriceResultViewController.swift"
)

is_bind_allowlisted() {
    local basename="$1"
    local entry
    for entry in "${BIND_ALLOWLIST[@]}"; do
        if [[ "${entry}" == "${basename}" ]]; then
            return 0
        fi
    done
    return 1
}

VC_FILES=$(find "${PRESENTATION_DIR}" -name "*ViewController.swift" -type f | sort)
VC_COUNT=0
VC_VIOLATIONS=0

if [[ -z "${VC_FILES}" ]]; then
    warn "No ViewController files found in Presentation/"
else
    while IFS= read -r file; do
        VC_COUNT=$((VC_COUNT + 1))
        RELATIVE="${file#"${REPO_ROOT}"/}"
        BASENAME="$(basename "$file")"

        if ! grep -q 'func bind(to' "$file"; then
            if is_bind_allowlisted "${BASENAME}"; then
                warn "${RELATIVE} — no bind(to:) (UI-only ViewController, allowlisted)"
            else
                violation "${RELATIVE} — missing: func bind(to"
                VC_VIOLATIONS=$((VC_VIOLATIONS + 1))
            fi
        else
            pass "${RELATIVE}"
        fi
    done <<< "${VC_FILES}"
fi

CHECKS=$((CHECKS + 1))
echo ""
echo -e "  Scanned ${BOLD}${VC_COUNT}${RESET} ViewController file(s), ${RED}${VC_VIOLATIONS} violation(s)${RESET}"

# ==============================================================================
# SUMMARY
# ==============================================================================
echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════${RESET}"

if [[ ${VIOLATIONS} -gt 0 ]]; then
    echo -e "${RED}${BOLD}  ✗ Pattern validation FAILED${RESET}"
    echo -e "    ${VIOLATIONS} violation(s) across ${CHECKS} checks, ${WARNINGS} warning(s)"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════${RESET}"
    echo ""
    exit 1
else
    echo -e "${GREEN}${BOLD}  ✓ Pattern validation passed (${CHECKS} checks, ${WARNINGS} warnings)${RESET}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════${RESET}"
    echo ""
    exit 0
fi
