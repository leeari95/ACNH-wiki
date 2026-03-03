# Finding Guidelines

코드 리뷰에서 이슈를 식별하고 작성하는 가이드라인입니다.

## Table of Contents

1. [8 Criteria for Valid Findings](#8-criteria-for-valid-findings)
2. [Priority System](#priority-system)
3. [ACNH-wiki Specific Rules](#acnh-wiki-specific-rules)
4. [Writing Quality Guidelines](#writing-quality-guidelines)
5. [JSON Output Schema](#json-output-schema)

---

## 8 Criteria for Valid Findings

이슈를 Finding으로 등록하기 전에 **8가지 기준**을 모두 충족해야 합니다:

| # | Criterion | Pass Example | Fail Example |
|---|-----------|--------------|--------------|
| 1 | **Real Impact** | Affects correctness, performance, security | General style preference |
| 2 | **Discrete & Actionable** | "Line 45 missing null check" | "Code could be cleaner" |
| 3 | **Appropriate Rigor** | Flagging missing `[weak self]` (team standard) | Requiring 100% coverage in prototype |
| 4 | **Introduced in This Change** | New line in diff violates convention | Pre-existing issue 20 lines above |
| 5 | **Author Would Fix** | Clear bug author didn't notice | Intentional design choice |
| 6 | **Based on Known Facts** | "Violates coding-conventions.md section 2.1" | "Might cause issues if API changes" |
| 7 | **Clear Scope** | "Method at line 45 crashes when userId is nil" | "Could cause problems elsewhere" |
| 8 | **Not Intentional** | Accidental pattern violation | Explicit design decision |

---

## Priority System

| Priority | Description | Examples |
|----------|-------------|----------|
| **P0** | Blocking - Must fix before merge | Crashes, critical bugs, data loss |
| **P1** | Urgent - Should fix soon | Memory leaks, major bugs, severe performance |
| **P2** | Eventually fix | Convention violations, minor bugs |
| **P3** | Nice to have | Docs, minor refactoring, style |

**JSON Title Format:**
- Always include `[P0]`, `[P1]`, `[P2]`, or `[P3]` prefix in JSON title
- Script automatically converts: `[P0]`/`[P1]` -> P0)/P1), `[P2]` -> (removed), `[P3]` -> NIT)

**Overall Correctness:**
- `"patch is correct"`: No P0/P1 bugs, code works as intended
- `"patch is incorrect"`: Has P0/P1 blocking issues

---

## ACNH-wiki Specific Rules

### False-Positive Prevention

**1. Coordinator Calls in reduce():**
- `coordinator?.transition(for:)` in `reduce()` is accepted project convention
- **DO NOT flag as side effect violation** - See gotchas.md #3
- Only flag OTHER side effects in reduce() (API calls, analytics, etc.)

**2. guard Statement Line Breaks:**
- Verify actual line breaks in diff, not assumed
- False alarm: Diff context may not show the blank line
- **Verify**: Check if blank line exists AFTER the guard statement's closing brace

**3. disposed(by:) Line Break:**
- **Violation**: `}.disposed(by: disposeBag)` (closing brace + disposed on same line)
- **Correct**: `}\n.disposed(by: disposeBag)` (line break after closing brace)
- Check actual diff, not assumed formatting

**4. ReactorKit Gotchas:**
- `mutate()`: Should return `Observable<Mutation>`, side effects allowed
- `reduce()`: Pure function (except coordinator transitions)
- `bind(to:)`: Standard VC binding pattern (2 exceptions allowlisted)
- Items.shared: Central data access point, don't bypass

**5. Layer Boundaries:**
- 13 Reactor files have CoreData default params (allowlisted)
- 1 Utility file references Presentation types (allowlisted)

---

## Writing Quality Guidelines

### Conciseness
- Max 1 paragraph body
- Max 3 lines of code in examples
- No unnecessary praise

### Clarity
- Explain WHY it's an issue
- Factual tone
- Author should grasp issue without deep reading

### Code References
- Use inline code or fenced code blocks
- Keep line ranges narrow (<=10 lines)
- Reference specific scenarios/conditions

### Example Finding

**JSON title:**
```
[P1] [weak self] 언랩핑 시 owner 대신 self 사용
```

**Body:**
```
클로저에서 `guard let self = self`를 사용하면 개발자 실수로 `[weak self]`
선언을 누락하여 retain cycle이 발생할 수 있습니다. 팀 컨벤션에 따라
`guard let owner = self`를 사용해야 합니다.
```

---

## JSON Output Schema

```json
{
  "findings": [
    {
      "title": "[P0] Title in imperative form (<=80 chars)",
      "body": "Valid markdown. Explain why it's a problem, reference file/line/function.",
      "confidence_score": 0.95,
      "priority": 0,
      "code_location": {
        "absolute_file_path": "/absolute/path/to/file.swift",
        "line_range": {"start": 45, "end": 47}
      }
    }
  ],
  "overall_correctness": "patch is correct",
  "overall_explanation": "1-3 sentences explaining overall verdict",
  "overall_confidence_score": 0.9
}
```

**Important Rules:**
- Include `[P0]`, `[P1]`, `[P2]`, or `[P3]` prefix in title
- Keep line_range narrow (5-10 lines max)
- No markdown fences around JSON
- No additional text before/after JSON

See [pending-review-guide.md](pending-review-guide.md) for complete transformation examples.
