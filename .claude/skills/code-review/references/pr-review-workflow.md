# PR Review Workflow

PR 리뷰 시 따라야 할 6단계 워크플로우입니다.

## Fundamental Principles

**Before you start any PR review, remember:**

1. **diff is sufficient for 99% of reviews** - `gh pr diff` provides enough context
2. **Branch checkout is the last resort** - Only when absolutely necessary
3. **Immediately return to original branch** - If you checkout, return BEFORE posting review

---

## Stage 1: Information Gathering (Original Branch)

**DO:**
```bash
# Save current branch
ORIGINAL_BRANCH=$(git branch --show-current)

# Get PR diff
.claude/skills/code-review/scripts/get-diff.sh <pr-number>
```

**Checkpoint:**
- [ ] PR info retrieved
- [ ] Diff visible
- [ ] Still on original branch

**NEVER:**
- Run `gh pr checkout` in this stage
- Read files with Read tool yet

---

## Stage 2: Load Guidelines (Original Branch)

**DO:**
- Read `references/coding-conventions.md`
- Read `references/architecture-guide.md`
- Read `.swiftlint.yml`

**Why original branch?** These files may not exist in PR branch.

**Checkpoint:**
- [ ] All reference files read
- [ ] Still on original branch

---

## Stage 3: Review from Diff (No Checkout)

**DO:**
- Analyze changes shown in diff
- Apply 8 criteria to identify issues (see [finding-guidelines.md](finding-guidelines.md))
- Check against coding conventions

**Most reviews end here (99% of cases).**

---

## Stage 4: Additional Context (ONLY IF NECESSARY)

**Checkout IS needed** (any of these):
1. Diff lacks context to understand surrounding code structure
2. Need to check relationships with other files/classes
3. Must see code outside diff range to judge pattern violation

**Checkout NOT needed** (stay with diff):
- Convention violation visible in changed lines
- Diff includes enough context (+-3 lines)
- Architecture pattern violation clear from diff alone

**If checkout truly needed:**
```bash
gh pr checkout <pr-number>
# Read MINIMUM necessary files only
git checkout $ORIGINAL_BRANCH  # IMMEDIATELY return
```

---

## Stage 5: Generate JSON Output (Original Branch)

Create JSON following schema in [finding-guidelines.md](finding-guidelines.md#json-output-schema).

---

## Stage 6: Post Review (Original Branch)

**Check Findings First:**

| Findings Count | Action |
|----------------|--------|
| 0 | Inform user "코드 리뷰 완료! 발견된 이슈가 없습니다." and END |
| > 0 | Execute script (unless user said "review only") |

**3-Step Workflow:**

1. **Verify Prerequisites:**
   - [ ] JSON output generated
   - [ ] On original branch
   - [ ] User did NOT say "review only"

2. **Execute Script:**
   ```bash
   echo '<json-output>' | .claude/skills/code-review/scripts/post-review-comments.sh --pr <PR_NUMBER>
   ```

3. **Provide User with Review URL**

---

## Common Mistakes

| Mistake | Wrong | Correct |
|---------|-------|---------|
| Reading references after checkout | `gh pr checkout 123` -> Read references (fails) | `get-diff.sh 123` -> Read references -> Review |
| Not returning after checkout | Checkout -> Read -> Generate JSON (fails) | Checkout -> Read -> `git checkout develop` -> Generate JSON |
| Unnecessary checkout | "Need to read file for accuracy" | "Diff shows enough context" |
