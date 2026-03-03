#!/bin/bash
# hook-doc-reminder.sh
# PostToolUse hook: reminds the agent to update documentation
# when structural files in any layer are created or modified.
#
# Reads JSON tool input from stdin and checks for file_path.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

# Only process .swift files in the project source tree
if ! echo "$FILE_PATH" | grep -q "Projects/App/Sources/.*\.swift$"; then
    exit 0
fi

# --- Presentation layer ---
if echo "$FILE_PATH" | grep -q "Presentation/"; then
    if echo "$FILE_PATH" | grep -qE "(Reactor|Coordinator|ViewController)\.swift$"; then
        cat <<'EOJSON'
{"message": "⚠️ Presentation 구조 변경 감지. 문서 업데이트 확인:\n- docs/features/*.md (해당 feature 문서)\n- docs/architecture.md (새 feature 추가 시)\n- scripts/validate-*.sh (새 allowlist 항목 필요 시)"}
EOJSON
    fi
    exit 0
fi

# --- Models layer ---
if echo "$FILE_PATH" | grep -q "/Models/"; then
    cat <<'EOJSON'
{"message": "⚠️ Models 변경 감지. 문서 업데이트 확인:\n- docs/glossary.md (새 도메인 타입 추가 시)\n- docs/architecture.md (레이어 구조 변경 시)"}
EOJSON
    exit 0
fi

# --- Networking layer ---
if echo "$FILE_PATH" | grep -q "/Networking/"; then
    cat <<'EOJSON'
{"message": "⚠️ Networking 변경 감지. 문서 업데이트 확인:\n- docs/guides/add-api-endpoint.md (새 API 패턴 시)\n- docs/patterns/data-flow.md (데이터 흐름 변경 시)"}
EOJSON
    exit 0
fi

# --- CoreDataStorage layer ---
if echo "$FILE_PATH" | grep -q "/CoreDataStorage/"; then
    cat <<'EOJSON'
{"message": "⚠️ CoreDataStorage 변경 감지. 문서 업데이트 확인:\n- docs/features/icloud-sync.md (CloudKit 동기화 관련 변경 시)\n- docs/guides/add-coredata-entity.md (새 Entity/Storage 시)\n- docs/patterns/data-flow.md (영속화 흐름 변경 시)"}
EOJSON
    exit 0
fi

# --- Utility layer (especially Items.swift) ---
if echo "$FILE_PATH" | grep -q "/Utility/"; then
    cat <<'EOJSON'
{"message": "⚠️ Utility 변경 감지. 문서 업데이트 확인:\n- docs/patterns/data-flow.md (Items.shared 스트림 변경 시)\n- docs/gotchas.md (새로운 주의사항 시)"}
EOJSON
    exit 0
fi

# --- SceneDelegate / AppDelegate ---
if echo "$FILE_PATH" | grep -qE "(SceneDelegate|AppDelegate)\.swift$"; then
    cat <<'EOJSON'
{"message": "⚠️ SceneDelegate/AppDelegate 변경 감지. 문서 업데이트 확인:\n- docs/architecture.md (앱 라이프사이클 변경 시)\n- docs/features/icloud-sync.md (CloudKit/토스트/계정 관련 변경 시)"}
EOJSON
    exit 0
fi

# --- Root coordinators (AppCoordinator, Coordinator protocol) ---
if echo "$FILE_PATH" | grep -qE "(AppCoordinator|Coordinator)\.swift$"; then
    cat <<'EOJSON'
{"message": "⚠️ Coordinator 프로토콜/AppCoordinator 변경 감지. 문서 업데이트 확인:\n- docs/patterns/coordinator-pattern.md\n- docs/architecture.md (탭 구조 변경 시)"}
EOJSON
    exit 0
fi
