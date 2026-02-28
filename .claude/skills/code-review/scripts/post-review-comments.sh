#!/bin/bash

# ACNH-wiki Code Review - PR Comment Posting Script (Claude-optimized)
# Claude가 코드 리뷰 결과를 GitHub PR에 pending review로 등록하는 스크립트
#
# 사용법:
#   ./post-review-comments.sh --pr <pr-number> --input <json-file>
#   ./post-review-comments.sh --pr <pr-number> < review-results.json

set -e

# GitHub CLI 확인
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh)가 설치되어 있지 않습니다." >&2
    echo "설치 방법: https://cli.github.com" >&2
    exit 1
fi

# jq 확인
if ! command -v jq &> /dev/null; then
    echo "Error: jq가 설치되어 있지 않습니다." >&2
    echo "설치 방법: brew install jq" >&2
    exit 1
fi

# 도움말 출력
print_help() {
    echo "사용법:"
    echo "  $0 --pr <pr-number> --input <json-file>"
    echo "  $0 --pr <pr-number> < review-results.json"
    echo "  $0 --pr <pr-number> --force < review-results.json"
    echo ""
    echo "옵션:"
    echo "  --pr <number>          PR 번호 (필수)"
    echo "  --input <file>         JSON 파일 경로 (선택, 미지정 시 stdin 사용)"
    echo "  --force                기존 pending review가 있으면 자동 삭제 후 진행"
    echo "  --help                 이 도움말 표시"
    echo ""
    echo "동작 방식 (pending review):"
    echo "  - GitHub에 'Start a review' 방식으로 리뷰를 시작합니다"
    echo "  - 기존 pending review가 있으면 에러 발생 (--force로 자동 삭제 가능)"
    echo "  - 사용자가 GitHub 웹에서 코멘트를 검토한 후"
    echo "  - 'Finish your review'를 클릭하여 Comment/Approve/Request changes 선택"
}

# 인자 파싱
PR_NUMBER=""
INPUT_FILE=""
FORCE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            print_help
            exit 0
            ;;
        --pr)
            PR_NUMBER="$2"
            shift 2
            ;;
        --input)
            INPUT_FILE="$2"
            shift 2
            ;;
        --force|-f)
            FORCE_MODE=true
            shift
            ;;
        *)
            echo "Error: 알 수 없는 옵션: $1" >&2
            print_help
            exit 1
            ;;
    esac
done

# PR 번호 확인
if [[ -z "$PR_NUMBER" ]]; then
    echo "Error: PR 번호를 지정해야 합니다 (--pr <number>)" >&2
    print_help
    exit 1
fi

# PR 번호에서 # 제거
PR_NUMBER="${PR_NUMBER#\#}"

# JSON 입력 읽기
if [[ -n "$INPUT_FILE" ]]; then
    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: 파일을 찾을 수 없습니다: $INPUT_FILE" >&2
        exit 1
    fi
    JSON_CONTENT=$(cat "$INPUT_FILE")
else
    JSON_CONTENT=$(cat)
fi

# JSON 유효성 검사
if ! echo "$JSON_CONTENT" | jq empty 2>/dev/null; then
    echo "Error: 유효하지 않은 JSON 형식입니다" >&2
    echo "Hint: stdin 파이프 대신 --input <file> 옵션 사용을 권장합니다" >&2
    echo "Debug: JSON 앞 200자:" >&2
    echo "$JSON_CONTENT" | head -c 200 >&2
    echo "" >&2
    exit 1
fi

# PR 존재 여부 및 repo 정보 확인
if ! gh pr view "$PR_NUMBER" --json number -q .number >/dev/null 2>&1; then
    echo "Error: PR #$PR_NUMBER를 찾을 수 없습니다" >&2
    exit 1
fi

# Repository owner와 name 가져오기
REPO_INFO=$(gh repo view --json owner,name)
REPO_OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')

# 현재 사용자 확인
CURRENT_USER=$(gh api user -q .login)

# 기존 pending review 확인
echo "=== Checking for existing pending reviews ==="
PENDING_REVIEWS=$(gh api "/repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/reviews" \
    --jq ".[] | select(.state == \"PENDING\" and .user.login == \"$CURRENT_USER\")")

if [[ -n "$PENDING_REVIEWS" ]]; then
    PENDING_REVIEW_ID=$(echo "$PENDING_REVIEWS" | jq -r '.id' | head -1)
    PENDING_REVIEW_URL=$(echo "$PENDING_REVIEWS" | jq -r '.html_url' | head -1)

    echo "  기존 pending review가 발견되었습니다:"
    echo "   Review ID: $PENDING_REVIEW_ID"
    echo "   URL: $PENDING_REVIEW_URL"
    echo ""

    if [[ "$FORCE_MODE" == true ]]; then
        echo "  --force 옵션이 지정되어 기존 pending review를 삭제합니다..."

        set +e
        DELETE_RESPONSE=$(gh api --method DELETE \
            "/repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/reviews/$PENDING_REVIEW_ID" 2>&1)
        DELETE_EXIT_CODE=$?
        set -e

        if [[ $DELETE_EXIT_CODE -eq 0 ]]; then
            echo "  기존 pending review가 삭제되었습니다."
            echo ""
        else
            echo "Error: 기존 pending review 삭제 실패" >&2
            echo "$DELETE_RESPONSE" >&2
            exit 1
        fi
    else
        echo "Error: 이미 pending review가 존재합니다." >&2
        echo "" >&2
        echo "다음 중 하나를 선택하세요:" >&2
        echo "  1. GitHub에서 기존 리뷰를 완료(Finish)하거나 삭제" >&2
        echo "     URL: $PENDING_REVIEW_URL" >&2
        echo "" >&2
        echo "  2. --force 플래그로 기존 리뷰를 자동 삭제:" >&2
        echo "     $0 --pr $PR_NUMBER --force < input.json" >&2
        echo "" >&2
        exit 1
    fi
else
    echo "  기존 pending review 없음"
    echo ""
fi

# JSON에서 데이터 추출
OVERALL_CORRECTNESS=$(echo "$JSON_CONTENT" | jq -r '.overall_correctness // "patch is correct"')
OVERALL_EXPLANATION=$(echo "$JSON_CONTENT" | jq -r '.overall_explanation // ""')
OVERALL_CONFIDENCE=$(echo "$JSON_CONTENT" | jq -r '.overall_confidence_score // 0')
FINDINGS_COUNT=$(echo "$JSON_CONTENT" | jq '.findings | length')

echo "=== Posting Code Review to PR ==="
echo ""
echo "PR: #$PR_NUMBER"
echo "Overall Correctness: $OVERALL_CORRECTNESS"
echo "Confidence Score: $OVERALL_CONFIDENCE"
echo "Findings Count: $FINDINGS_COUNT"
echo ""
echo "Mode: Pending Review (리뷰어가 GitHub에서 최종 검토)"
echo ""

# 전체 요약 본문 생성
generate_summary_body() {
    if [[ "$OVERALL_CORRECTNESS" == "patch is correct" ]]; then
        if [[ "$FINDINGS_COUNT" -gt 0 ]]; then
            cat <<EOF
## 자동 코드 리뷰 결과

**전체 판정**: 패치가 올바릅니다

**설명**: $OVERALL_EXPLANATION

**발견된 이슈**: ${FINDINGS_COUNT}개 (각 이슈는 해당 파일의 코드 라인에 코멘트로 표시됩니다)

---
_이 리뷰는 [Claude Code](https://claude.com/claude-code) 코드리뷰 스킬에 의해 생성되었으며, 리뷰어의 최종 검토를 거쳐 제출됩니다._
EOF
        else
            cat <<EOF
## 자동 코드 리뷰 결과

**전체 판정**: 패치가 올바릅니다

**설명**: $OVERALL_EXPLANATION

**발견된 이슈**: 없음

모든 변경사항이 팀 코딩 컨벤션과 베스트 프랙티스를 준수합니다.

---
_이 리뷰는 [Claude Code](https://claude.com/claude-code) 코드리뷰 스킬에 의해 생성되었으며, 리뷰어의 최종 검토를 거쳐 제출됩니다._
EOF
        fi
    else
        cat <<EOF
## 자동 코드 리뷰 결과

**전체 판정**: 패치에 문제가 있습니다

**설명**: $OVERALL_EXPLANATION

**발견된 이슈**: ${FINDINGS_COUNT}개 (각 이슈는 해당 파일의 코드 라인에 코멘트로 표시됩니다)

---
_이 리뷰는 [Claude Code](https://claude.com/claude-code) 코드리뷰 스킬에 의해 생성되었으며, 리뷰어의 최종 검토를 거쳐 제출됩니다._
EOF
    fi
}

# 각 finding에 대한 인라인 코멘트 본문 생성
generate_inline_comment_body() {
    local i=$1
    local title=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].title")
    local finding_body=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].body")
    local priority=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].priority // null")

    # priority tag 제거 (예: "[P1] " 부분 제거)
    title=$(echo "$title" | sed -E 's/^\[P[0-3]\] //')

    # 우선순위 표시 방식
    local prefix=""
    case $priority in
        0|1) prefix="P${priority}) " ;;
        2) prefix="" ;;
        3) prefix="NIT) " ;;
        *) prefix="" ;;
    esac

    cat <<EOF
**${prefix}${title}**

${finding_body}
EOF
}

# PR HEAD commit SHA 가져오기
PR_HEAD_SHA=$(gh pr view "$PR_NUMBER" --json headRefOid -q .headRefOid 2>/dev/null)

# Repo 루트 경로 (절대→상대 경로 변환용)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

# 전체 요약 본문 생성
SUMMARY_BODY=$(generate_summary_body)

# Review JSON 생성 (body + inline comments)
build_review_json() {
    local json_body=$(echo "$SUMMARY_BODY" | jq -Rs .)

    # comments 배열 시작
    local comments="["

    if [[ "$FINDINGS_COUNT" -gt 0 ]]; then
        for i in $(seq 0 $((FINDINGS_COUNT - 1))); do
            local file_path=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].code_location.absolute_file_path // \"\"")
            local line_start=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].code_location.line_range.start // 0")
            local line_end=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].code_location.line_range.end // 0")

            if [[ -n "$file_path" && "$file_path" != "null" && "$line_start" -gt 0 ]]; then
                # 절대 경로를 repo 루트 기준 상대 경로로 변환
                local relative_path="$file_path"
                if [[ -n "$REPO_ROOT" ]]; then
                    relative_path="${file_path#$REPO_ROOT/}"
                fi

                # 인라인 코멘트 본문 생성
                local comment_body=$(generate_inline_comment_body $i)
                local comment_body_json=$(echo "$comment_body" | jq -Rs .)

                # 쉼표 추가 (첫 번째가 아닌 경우)
                if [[ "$i" -gt 0 ]]; then
                    comments+=","
                fi

                # 단일 라인 또는 멀티 라인 코멘트
                if [[ "$line_start" == "$line_end" ]]; then
                    comments+="{\"path\":\"$relative_path\",\"line\":$line_end,\"body\":$comment_body_json}"
                else
                    comments+="{\"path\":\"$relative_path\",\"start_line\":$line_start,\"line\":$line_end,\"body\":$comment_body_json}"
                fi
            fi
        done
    fi

    comments+="]"

    # 최종 JSON 조합
    echo "{\"commit_id\":\"$PR_HEAD_SHA\",\"body\":$json_body,\"comments\":$comments}"
}

REVIEW_JSON=$(build_review_json)

# 미리보기
echo "=== Review Preview ==="
echo ""
echo "Summary:"
echo "$SUMMARY_BODY"
echo ""
if [[ "$FINDINGS_COUNT" -gt 0 ]]; then
    echo "Inline Comments ($FINDINGS_COUNT):"
    for i in $(seq 0 $((FINDINGS_COUNT - 1))); do
        preview_file_path=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].code_location.absolute_file_path // \"\"")
        preview_line_start=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].code_location.line_range.start // 0")
        preview_line_end=$(echo "$JSON_CONTENT" | jq -r ".findings[$i].code_location.line_range.end // 0")
        preview_relative_path="$preview_file_path"
        if [[ -n "$REPO_ROOT" ]]; then
            preview_relative_path="${preview_file_path#$REPO_ROOT/}"
        fi

        if [[ "$preview_line_start" == "$preview_line_end" ]]; then
            echo "  [$((i+1))] $preview_relative_path:$preview_line_end"
        else
            echo "  [$((i+1))] $preview_relative_path:$preview_line_start-$preview_line_end"
        fi

        preview_comment_body=$(generate_inline_comment_body $i)
        echo "$preview_comment_body" | sed 's/^/      /'
        echo ""
    done
fi
echo ""

# 리뷰 생성
echo "=== Creating Review ==="
echo ""
echo "Creating pending review..."

set +e
REVIEW_RESPONSE=$(echo "$REVIEW_JSON" | gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/reviews" \
    --input - 2>&1)
REVIEW_EXIT_CODE=$?
set -e

if [[ $REVIEW_EXIT_CODE -eq 0 ]]; then
    REVIEW_ID=$(echo "$REVIEW_RESPONSE" | jq -r '.id')
    REVIEW_HTML_URL=$(echo "$REVIEW_RESPONSE" | jq -r '.html_url')

    echo "Success: Pending review created!"
    echo ""
    echo "=== Next Steps ==="
    echo ""
    echo "1. Review the comments on GitHub:"
    echo "   $REVIEW_HTML_URL"
    echo ""
    echo "2. Choose one of the following:"
    echo "   - Approve: 변경사항 승인"
    echo "   - Comment: 코멘트만 남기기"
    echo "   - Request changes: 수정 요청"
    echo ""
    echo "3. Click 'Finish your review' to submit"
    echo ""
else
    echo "Error: Failed to create pending review" >&2
    echo "$REVIEW_RESPONSE" >&2
    exit 1
fi

# PR URL 표시
echo ""
PR_URL=$(gh pr view "$PR_NUMBER" --json url -q .url 2>/dev/null)
echo "PR URL: $PR_URL"
echo ""
echo "=== Complete ==="
