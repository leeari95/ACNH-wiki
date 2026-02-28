---
name: code-review
description: >
  ACNH-wiki 프로젝트의 코드 변경사항을 다중 관점으로 리뷰하고, 버그, 성능, 보안,
  코딩 컨벤션 위반사항을 JSON 형식으로 출력한다.
  사용 시점: (1) PR 코드 리뷰 요청 시 ("이 PR 리뷰해줘", "코드 리뷰 부탁", "PR 검토해줘")
  (2) 커밋 리뷰 시 ("이 커밋 검토해줘", "커밋 리뷰해줘")
  (3) 현재 변경사항 리뷰 시 ("지금 변경사항 리뷰해줘", "내가 바꾼 코드 검토해줘", "코드 리뷰")
  (4) GitHub PR에 리뷰 코멘트 등록 요청 시
---

# ACNH-wiki Code Review Skill

Multi-perspective code review using specialized reviewer agents in parallel.

## Review Modes

**FIRST STEP: Ask user to select review scope** using AskUserQuestion tool:

```json
{
  "questions": [
    {
      "question": "어떤 범위의 코드를 리뷰할까요?",
      "header": "리뷰 범위",
      "multiSelect": false,
      "options": [
        {
          "label": "현재 변경사항 (Recommended)",
          "description": "Staged + unstaged 모든 커밋되지 않은 변경사항을 리뷰합니다."
        },
        {
          "label": "특정 커밋",
          "description": "커밋 해시를 지정하여 해당 커밋의 변경사항만 리뷰합니다."
        },
        {
          "label": "Pull Request",
          "description": "GitHub PR 번호를 지정하여 PR의 모든 변경사항을 리뷰하고 GitHub에 코멘트를 등록합니다."
        }
      ]
    }
  ]
}
```

---

## Core Workflow

### Step 1: Gather Changes

```bash
# Current changes
.claude/skills/code-review/scripts/get-diff.sh

# Specific commit
.claude/skills/code-review/scripts/get-diff.sh <commit-hash>

# Pull Request (diff is sufficient for 99% of reviews)
.claude/skills/code-review/scripts/get-diff.sh <pr-number>
```

### Step 2: Diff Size Guard

After gathering the diff, assess its size to ensure review quality:

```bash
# Check diff stats
.claude/skills/code-review/scripts/get-diff.sh --stat
```

| Condition | Action |
|-----------|--------|
| Swift files = 0 (only .md, .json, .xcconfig, etc.) | Run `reviewer-conventions` only, skip other 4 agents |
| Changed files > 30 OR diff > 5,000 lines | AskUserQuestion: "변경 범위가 큽니다. 전체 리뷰 vs 주요 파일만 선택할까요?" |
| Otherwise | Proceed normally with all 5 agents |

### Step 3: Load Review Guidelines

Read the following skill-local reference files (always available on current branch):
- `references/coding-conventions.md` - Team coding conventions
- `references/architecture-guide.md` - Architecture patterns (ReactorKit, Coordinator, etc.)

These contents will be included in the agent prompt (see Step 4).

> **PR reviews**: If you need to access source files on the PR branch, see [pr-review-workflow.md](references/pr-review-workflow.md) Stage 1.

### Step 4: Phase 1 - Parallel Agent Execution

**Run 5 reviewers in parallel** using Task tool (project-local agents in `.claude/agents/`).

**IMPORTANT**: Call all 5 Task tools in a **single message** for parallel execution.

#### Agent Prompt Template

Each agent receives the **same structured prompt**:

```
You are reviewing code changes for the ACNH-wiki (너굴포털+) project.

## Review Metadata
- Mode: [Current Changes | Commit <hash> | PR #<number>]
- Changed Files: [file list extracted from diff headers]

## Coding Conventions Reference
<full contents of references/coding-conventions.md>

## Architecture Guide Reference
<full contents of references/architecture-guide.md>

## Diff to Review
Each diff line includes an explicit line number (e.g., `+  79: code`).
Use these numbers directly for `code_location.line_range` values. Do NOT count lines manually.
<full diff content from Step 1>
```

#### Invocation

```
Task(subagent_type="reviewer-swift-ios", prompt="<structured prompt>")
Task(subagent_type="reviewer-correctness", prompt="<structured prompt>")
Task(subagent_type="reviewer-security", prompt="<structured prompt>")
Task(subagent_type="reviewer-code-quality", prompt="<structured prompt>")
Task(subagent_type="reviewer-conventions", prompt="<structured prompt>")
```

> **Note**: Agents are defined in `.claude/agents/` directory. No plugin installation required.

### Step 5: Phase 2 - False Positive Filter

After collecting **all Phase 1 results**, run the `false-positive-filter` agent for compound verification.

#### FP Filter Prompt Template

```
You are validating Phase 1 code review findings for ACNH-wiki.

## Phase 1 Findings (ALL priorities)
<JSON array of all findings from the 5 Phase 1 reviewers>

## Original Diff
<full diff content from Step 1>

Validate each finding using compound verification.
Output verdicts: TRUE_POSITIVE, FALSE_POSITIVE, DOWNGRADE, or UPGRADE.
```

#### Invocation

```
Task(subagent_type="false-positive-filter", prompt="<structured prompt>")
```

#### FP Filter Verdicts

| Verdict | Action |
|---------|--------|
| `TRUE_POSITIVE` | Keep finding as-is |
| `FALSE_POSITIVE` | Remove finding from final output |
| `DOWNGRADE` | Lower priority (e.g., P1 -> P2) with reason |
| `UPGRADE` | Raise priority (e.g., P2 -> P0) with evidence |

### Step 6: Aggregate & Deduplicate

Collect validated findings from Phase 2 and deduplicate:

#### Deduplication Rules

1. **Same file + overlapping line range (+-3 lines)** -> Merge as single issue
   - `priority`: Use the higher (more severe) value
   - `body`: Use the more detailed description
   - `reviewer`: List all contributing reviewers (e.g., `"reviewer-swift-ios, reviewer-correctness"`)

2. **Same file, non-overlapping lines** -> Keep as separate issues

3. **Same code location, different categories** -> Keep both if perspectives genuinely differ
   - e.g., Safety (swift-ios) + Correctness -> two separate findings

#### Validation

- P0/P1 findings **MUST** include all 3 evidence items (Pattern, Proof, Impact)
- **If ANY evidence missing -> Downgrade to P2/P3**
- Remove all `FALSE_POSITIVE` findings from final output
- Apply `DOWNGRADE`/`UPGRADE` priority adjustments from FP Filter

### Step 7: Generate Final Output

```json
{
  "findings": [
    {
      "reviewer": "reviewer-swift-ios",
      "category": "Memory Safety",
      "title": "[P1] Issue title (<=80 chars)",
      "body": "Description with evidence, reference file/line",
      "confidence_score": 0.95,
      "priority": 1,
      "code_location": {
        "absolute_file_path": "/path/to/file.swift",
        "line_range": {"start": 45, "end": 47}
      }
    }
  ],
  "overall_correctness": "patch is correct | patch is incorrect",
  "overall_explanation": "1-3 sentences summary",
  "overall_confidence_score": 0.9
}
```

**Review State Decision**:

| Condition | Result |
|-----------|--------|
| P0 > 0 OR P1 > 0 | `"patch is incorrect"` |
| P0 = 0 AND P1 = 0 | `"patch is correct"` |

### Step 8: Post to GitHub (PR Reviews Only)

**If findings count is 0:**
- Inform user: "코드 리뷰 완료! 발견된 이슈가 없습니다."
- **END** workflow (no GitHub comment needed)

**If findings count > 0:**

1. Check for existing pending review:
   ```bash
   gh api "/repos/leeari95/ACNH-wiki/pulls/<PR_NUMBER>/reviews" \
     --jq '.[] | select(.state == "PENDING") | {id, user: .user.login}'
   ```

2. If pending exists: AskUserQuestion to confirm deletion, add `--force`

3. Execute script:
   ```bash
   echo '<json>' | .claude/skills/code-review/scripts/post-review-comments.sh --pr <PR_NUMBER>
   ```

---

## Reviewer Agents

Project-local agents defined in `.claude/agents/`:

| Agent | Model | Focus | File |
|-------|-------|-------|------|
| `reviewer-swift-ios` | sonnet | Memory safety, RxSwift safety, Concurrency, Performance safety | [reviewer-swift-ios.md](../../agents/reviewer-swift-ios.md) |
| `reviewer-correctness` | sonnet | Logic errors, RxSwift stream correctness, ReactorKit flow correctness | [reviewer-correctness.md](../../agents/reviewer-correctness.md) |
| `reviewer-security` | **opus** | OWASP M1-M10, Privacy, Data protection, CoreData/CloudKit security | [reviewer-security.md](../../agents/reviewer-security.md) |
| `reviewer-code-quality` | sonnet | ReactorKit architecture, Coordinator pattern, Networking, Maintainability | [reviewer-code-quality.md](../../agents/reviewer-code-quality.md) |
| `reviewer-conventions` | sonnet | Coding conventions (naming, formatting, RxSwift style, localization) | [reviewer-conventions.md](../../agents/reviewer-conventions.md) |
| `false-positive-filter` | opus | Agent-specific validation, compound verification, UPGRADE/DOWNGRADE | [false-positive-filter.md](../../agents/false-positive-filter.md) |

---

## Priority Classification

> **CRITICAL**: Same issue = same priority regardless of context.

### P0 (Blocker)

- Force unwrap on nil / Force try in production
- Retain cycle / Strong delegate
- Data race / Deadlock
- Data loss / Security bypass
- Hardcoded credentials

### P1 (Must Fix)

- Missing [weak self] in async closure
- `guard let self = self` (should be owner)
- Empty catch block
- Wrong output for common input
- Missing auth check

### P2 (Should Fix)

- disposed(by:) on same line as `}`
- Missing guard blank line
- Edge case failure
- Localization key missing in one lproj

### P3 (Nice to Have)

- Naming suggestions
- Style improvements
- Theoretical issues

---

## Evidence Requirements (P0/P1)

**ALL P0/P1 findings MUST include**:

1. **Pattern/Violation**: What rule/pattern is violated
2. **Proof**: Code path, crash scenario, or test case
3. **Impact**: User-facing? Data affected? Scope?

**If ANY missing -> Downgrade to P2/P3**

---

## Quick Reference: Common Violations

| Violation | Wrong | Correct | Priority |
|-----------|-------|---------|----------|
| weak self | `guard let self = self` | `guard let owner = self` | P1 |
| disposed | `}.disposed(by:)` | `}\n.disposed(by:)` | P2 |
| guard | `guard...\ncode()` | `guard...\n\ncode()` | P2 |
| localization | `NSLocalizedString(...)` | `"key".localized` | P2 |
| Coordinator bypass | `present(vc, animated:)` | `coordinator?.transition(for:)` | P1 |

---

## Scripts

### get-diff.sh

```bash
.claude/skills/code-review/scripts/get-diff.sh                    # Current changes
.claude/skills/code-review/scripts/get-diff.sh <commit-hash>      # Specific commit
.claude/skills/code-review/scripts/get-diff.sh <pr-number>        # Pull Request
```

### post-review-comments.sh

```bash
echo '<json>' | .claude/skills/code-review/scripts/post-review-comments.sh --pr <pr-number>
```

**Flags**: `--pr <number>`, `--input <file>`, `--force`

---

## References

| File | Contents |
|------|----------|
| [coding-conventions.md](references/coding-conventions.md) | ACNH-wiki coding conventions |
| [architecture-guide.md](references/architecture-guide.md) | ReactorKit, Coordinator, Data flow patterns |
| [finding-guidelines.md](references/finding-guidelines.md) | 8 criteria, JSON schema |
| [pr-review-workflow.md](references/pr-review-workflow.md) | 6-stage PR workflow |
| [pending-review-guide.md](references/pending-review-guide.md) | GitHub comment format |
