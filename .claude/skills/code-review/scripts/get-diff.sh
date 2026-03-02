#!/bin/bash

# ACNH-wiki Code Review - Diff Retrieval Script (Claude-optimized)
# Claude가 코드 리뷰를 위한 변경사항 diff를 가져오는 스크립트
#
# 사용법:
#   ./get-diff.sh                    # 현재 변경사항 (unstaged + staged)
#   ./get-diff.sh <commit-hash>      # 특정 커밋의 변경사항
#   ./get-diff.sh <pr-number>        # PR의 변경사항 (예: 123 또는 #123)
#   ./get-diff.sh --stat             # 현재 변경사항 통계만
#   ./get-diff.sh <commit-hash> --stat  # 특정 커밋 통계만
#   ./get-diff.sh <pr-number> --stat    # PR 통계만

set -e

# Git 저장소 확인
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: 현재 디렉토리가 Git 저장소가 아닙니다." >&2
    exit 1
fi

# GitHub CLI 확인 (PR 기능용)
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh)가 설치되어 있지 않습니다." >&2
        echo "설치 방법: https://cli.github.com" >&2
        exit 1
    fi
}

# 도움말 출력
print_help() {
    echo "사용법:"
    echo "  $0                         # 현재 변경사항 (unstaged + staged)"
    echo "  $0 <commit-hash>           # 특정 커밋의 변경사항"
    echo "  $0 <pr-number>             # PR의 변경사항 (예: 123 또는 #123)"
    echo "  $0 --stat                  # 현재 변경사항 통계만"
    echo "  $0 <commit-hash> --stat    # 특정 커밋 통계만"
    echo "  $0 <pr-number> --stat      # PR 통계만"
    echo ""
    echo "옵션:"
    echo "  --stat                     # 파일별 변경 통계만 표시"
    echo "  --help                     # 이 도움말 표시"
}

# 인자 파싱
TARGET=""
STAT_ONLY=false

for arg in "$@"; do
    case $arg in
        --help|-h)
            print_help
            exit 0
            ;;
        --stat)
            STAT_ONLY=true
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$arg"
            fi
            ;;
    esac
done

# PR 번호인지 확인 (순수 숫자 또는 #으로 시작하는 숫자)
is_pr_number() {
    local input="$1"
    input="${input#\#}"
    [[ "$input" =~ ^[0-9]+$ ]]
}

# PR 번호에서 # 제거
clean_pr_number() {
    local input="$1"
    echo "${input#\#}"
}

# diff 출력에 새 파일 기준 라인 번호 추가 (에이전트의 라인 카운팅 오류 방지)
# 출력 형식:
#   +  79: code   → 추가 라인 (새 파일 79번째 줄)
#    123: code   → 컨텍스트 라인 (새 파일 기준)
#   -code         → 삭제 라인 (번호 없음)
add_line_numbers() {
    awk '
    /^diff --git/ { in_hunk = 0; print; next }
    /^index / || /^--- / || /^\+\+\+ / || /^Binary/ || /^old mode/ || /^new mode/ || /^rename/ || /^similarity/ || /^dissimilarity/ || /^copy/ {
        print; next
    }
    /^@@ / {
        in_hunk = 1
        split($2, old_arr, ",")
        old_line = substr(old_arr[1], 2) + 0
        split($3, new_arr, ",")
        new_line = substr(new_arr[1], 2) + 0
        print; next
    }
    in_hunk && /^\+/ {
        printf "+%4d: %s\n", new_line, substr($0, 2)
        new_line++; next
    }
    in_hunk && /^-/ {
        print; old_line++; next
    }
    in_hunk && /^ / {
        printf " %4d: %s\n", new_line, substr($0, 2)
        new_line++; old_line++; next
    }
    { print }
    '
}

# 현재 변경사항 가져오기
get_current_changes() {
    echo "=== Current Changes ==="
    echo ""

    # Git 상태 확인
    echo "Git Status:"
    git status --short
    echo ""

    # Unstaged changes
    if git diff --quiet; then
        echo "Unstaged Changes: None"
    else
        echo "Unstaged Changes:"
        echo "----------------------------------------"
        if [ "$STAT_ONLY" = true ]; then
            git diff --stat
        else
            git diff | add_line_numbers
        fi
        echo ""
    fi

    # Staged changes
    if git diff --cached --quiet; then
        echo "Staged Changes: None"
    else
        echo "Staged Changes:"
        echo "----------------------------------------"
        if [ "$STAT_ONLY" = true ]; then
            git diff --cached --stat
        else
            git diff --cached | add_line_numbers
        fi
        echo ""
    fi

    # 변경사항이 하나도 없는 경우
    if git diff --quiet && git diff --cached --quiet; then
        echo "Warning: 변경사항이 없습니다."
        echo "커밋되지 않은 파일이 있다면 git add를 먼저 실행하세요."
        exit 0
    fi
}

# 특정 커밋 변경사항 가져오기
get_commit_changes() {
    local commit="$1"

    # 커밋 해시 유효성 검사
    if ! git rev-parse --verify "$commit" > /dev/null 2>&1; then
        echo "Error: 유효하지 않은 커밋 해시입니다: $commit" >&2
        echo "최근 커밋 목록:" >&2
        git log --oneline -5 >&2
        exit 1
    fi

    # 전체 커밋 해시 가져오기
    local full_hash
    full_hash=$(git rev-parse "$commit")

    echo "=== Commit Changes ==="
    echo ""

    # 커밋 정보 표시
    echo "Commit: $full_hash"
    echo "Author: $(git show -s --format='%an <%ae>' "$commit")"
    echo "Date: $(git show -s --format='%ad' --date=format:'%Y-%m-%d %H:%M:%S' "$commit")"
    echo ""
    echo "Commit Message:"
    git show -s --format='%B' "$commit" | sed 's/^/  /'
    echo ""

    # 변경사항 표시
    echo "Changes:"
    echo "----------------------------------------"

    if [ "$STAT_ONLY" = true ]; then
        git show --stat "$commit"
    else
        git show "$commit" | add_line_numbers
    fi
}

# PR 변경사항 가져오기
get_pr_changes() {
    local pr_number="$1"

    # GitHub CLI 확인
    check_gh_cli

    # PR 존재 여부 확인
    if ! gh pr view "$pr_number" --json number -q .number >/dev/null 2>&1; then
        echo "Error: PR #$pr_number를 찾을 수 없습니다." >&2
        echo "최근 PR 목록:" >&2
        gh pr list --limit 5 2>/dev/null >&2 || echo "(PR 목록을 가져올 수 없습니다)" >&2
        exit 1
    fi

    echo "=== Pull Request Changes ==="
    echo ""

    # PR 정보 가져오기
    local pr_title pr_author pr_state pr_base pr_head pr_url pr_created pr_body
    pr_title=$(gh pr view "$pr_number" --json title -q .title)
    pr_author=$(gh pr view "$pr_number" --json author -q .author.login)
    pr_state=$(gh pr view "$pr_number" --json state -q .state)
    pr_base=$(gh pr view "$pr_number" --json baseRefName -q .baseRefName)
    pr_head=$(gh pr view "$pr_number" --json headRefName -q .headRefName)
    pr_url=$(gh pr view "$pr_number" --json url -q .url)
    pr_created=$(gh pr view "$pr_number" --json createdAt -q .createdAt)
    pr_body=$(gh pr view "$pr_number" --json body -q .body)

    # PR 정보 표시
    echo "PR: #$pr_number"
    echo "Title: $pr_title"
    echo "Author: $pr_author"
    echo "State: $pr_state"
    echo "Branch: $pr_head -> $pr_base"
    echo "Created: $pr_created"
    echo "URL: $pr_url"
    echo ""

    # PR 설명 표시 (비어있지 않은 경우)
    if [[ -n "$pr_body" && "$pr_body" != "null" ]]; then
        echo "Description:"
        echo "$pr_body" | sed 's/^/  /'
        echo ""
    fi

    # 변경사항 표시
    echo "Changes:"
    echo "----------------------------------------"

    if [ "$STAT_ONLY" = true ]; then
        echo "Files Changed:"
        gh pr diff "$pr_number" --name-only 2>/dev/null
        echo ""
        echo "Diff Stat:"
        local additions deletions changed_files
        additions=$(gh pr view "$pr_number" --json additions -q .additions 2>/dev/null)
        deletions=$(gh pr view "$pr_number" --json deletions -q .deletions 2>/dev/null)
        changed_files=$(gh pr view "$pr_number" --json changedFiles -q .changedFiles 2>/dev/null)
        echo "  ${changed_files} files changed, +$additions insertions(+), -$deletions deletions(-)"
    else
        local diff_output
        diff_output=$(gh pr diff "$pr_number" 2>/dev/null) || {
            echo "Error: PR diff를 가져올 수 없습니다." >&2
            exit 1
        }
        echo "$diff_output" | add_line_numbers
    fi

    echo ""
    echo "Review Summary:"
    local comments_count
    comments_count=$(gh pr view "$pr_number" --json comments -q '.comments | length')
    echo "  Comments: $comments_count"

    # 리뷰 상태 확인
    local reviews_state
    reviews_state=$(gh pr view "$pr_number" --json reviewDecision -q .reviewDecision)
    if [[ -n "$reviews_state" && "$reviews_state" != "null" ]]; then
        echo "  Review Decision: $reviews_state"
    fi
}

# 메인 로직
main() {
    if [[ -z "$TARGET" ]]; then
        get_current_changes
    elif is_pr_number "$TARGET"; then
        local pr_num
        pr_num=$(clean_pr_number "$TARGET")
        get_pr_changes "$pr_num"
    else
        get_commit_changes "$TARGET"
    fi
}

main
