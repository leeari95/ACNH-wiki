# Pending Review Guide

This guide explains the GitHub pending review mechanism and how the `post-review-comments.sh` script works.

## What is a Pending Review?

A **pending review** is a draft review on GitHub that hasn't been submitted yet. It allows reviewers to:
- Add multiple comments across different files
- Preview all comments together before publishing
- Edit or delete comments before submission
- Choose final verdict (Approve/Comment/Request Changes) when ready

### How `post-review-comments.sh` Creates Pending Reviews

The script follows these 5 steps:

1. **JSON Validation**: Verifies the input JSON has all required fields
2. **PR Verification**: Confirms the specified PR exists
3. **Review Body Generation**: Converts priority tags, formats findings
4. **Preview Output**: Displays the generated comment body for verification
5. **Pending Review Creation**: Uses `gh api` to create pending review

### Why Pending (Not Auto-Submitted)?

Pending reviews give the reviewer (human) final control:
- Review before publishing
- Edit if needed
- Choose verdict based on context
- Avoid spam if review quality is low

---

## GitHub Comment Format

### Priority Display Mapping

| JSON Priority Tag | GitHub Display | Prefix |
|-------------------|----------------|--------|
| `[P0]` | P0) Title | P0) |
| `[P1]` | P1) Title | P1) |
| `[P2]` | Title | (removed) |
| `[P3]` | NIT) Title | NIT) |

---

## Complete JSON->GitHub Transformation Example

### Input JSON

```json
{
  "findings": [
    {
      "title": "[P1] [weak self] 언랩핑 시 owner 대신 self 사용",
      "body": "클로저에서 `guard let self = self`를 사용하면 개발자 실수로 `[weak self]` 선언을 누락하여 retain cycle이 발생할 수 있습니다.",
      "confidence_score": 0.95,
      "priority": 1,
      "code_location": {
        "absolute_file_path": "/Users/Ari/Documents/git/ACNH-wiki/Projects/App/Sources/Presentation/Dashboard/ViewModels/DashboardReactor.swift",
        "line_range": {"start": 45, "end": 47}
      }
    },
    {
      "title": "[P2] disposed(by:) 줄바꿈 누락",
      "body": "클로저 닫는 괄호 `}` 바로 뒤에 `.disposed(by: disposeBag)`가 같은 줄에 작성되어 있습니다.",
      "confidence_score": 1.0,
      "priority": 2,
      "code_location": {
        "absolute_file_path": "/Users/Ari/Documents/git/ACNH-wiki/Projects/App/Sources/Presentation/Catalog/ViewControllers/CatalogViewController.swift",
        "line_range": {"start": 52, "end": 55}
      }
    }
  ],
  "overall_correctness": "patch is correct",
  "overall_explanation": "P1-P2 레벨의 컨벤션 위반이 있지만 기능적으로는 정상 동작하며 블로킹 이슈는 없습니다.",
  "overall_confidence_score": 0.9
}
```

### GitHub Output

**Title Transformations:**
- `[P1] [weak self] 언랩핑...` -> `P1) [weak self] 언랩핑...`
- `[P2] disposed(by:) 줄바꿈 누락` -> `disposed(by:) 줄바꿈 누락`

---

## Troubleshooting

### Issue: Script says "Error: GitHub CLI (gh) not installed"

**Solution:** Install GitHub CLI:
```bash
brew install gh
```

### Issue: Script says "Error: jq not installed"

**Solution:** Install jq:
```bash
brew install jq
```

### Issue: Script says "Error: PR #123 not found"

**Solution:**
```bash
gh auth status
gh auth login
gh pr view 123
```

### Issue: Pending review not visible on GitHub

**Solution:**
1. Ensure script execution: Check for success message
2. Verify branch: `git branch --show-current`
3. Check permissions: Ensure you have review access

---

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- `jq` installed (`brew install jq`)
- PR review permissions
- Original branch (script must be run from the original branch)
