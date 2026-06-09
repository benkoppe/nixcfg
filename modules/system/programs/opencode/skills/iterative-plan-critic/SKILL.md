---
name: iterative-plan-critic
description: Use when refining a non-trivial implementation plan with fresh read-only criticizer subagents before coding. Trigger on requests like "criticize this plan in an iterative loop", "iterate until no criticisms", "make this plan robust iteratively", or "run a criticizer loop".
---

# Iterative Plan Critic

Use this skill to turn an implementation plan into a stronger, executable plan before writing code.

## When To Use

Use when:

- The user asks for a plan to be criticized or hardened.
- The task is architecture-heavy, cross-cutting, or risky.
- The plan involves schemas, migrations, APIs, validation rules, security boundaries, or multi-step implementation.
- The user asks to keep iterating until a criticizer stops criticizing.
  Do not use for:
- Simple one-file edits.
- Pure code review of already-written changes.
- Tasks where the user explicitly wants implementation immediately without planning.

## Workflow

1. Build the current plan first.
2. Launch a fresh read-only criticizer subagent.
3. Ask it to identify only concrete plan defects.
4. For each criticism, decide whether it is valid, partly valid, invalid, or preference-only.
5. Apply only valid or partly valid criticism to the plan.
6. Repeat with a fresh criticizer only while it reports new Blocking or Material defects.
7. Stop when remaining feedback is Minor, preference-only, duplicated, speculative, or non-actionable.
8. Return the final plan plus a short note that the criticizer loop converged.

## Criticizer Prompt Template

Use this prompt for each fresh criticizer:

```text
You are a fresh criticizer subagent.
Work read-only only:
- Do not edit files.
- Do not modify the repo.
- Do not run commands that write files.
Criticize the implementation plan below for this repo.
Compare it against relevant project docs if useful, especially:
- PLAN.md
- GUIDELINES.md and/or ARCHITECTURE.md (if present)
- language-important files like Cargo workspace/etc
- Any task-specific docs
Focus only on concrete defects that would cause:
- Wrong implementation
- Ambiguity
- Scope creep
- Missing validation
- Dependency/API risk
- Non-executable instructions
- Conflicts with repo guidelines or architecture
Classify each criticism as one of:
- Blocking: likely to cause wrong implementation, broken behavior, unsafe behavior, or a non-executable plan.
- Material: likely to waste significant time or require rework, but not fatal.
- Minor: wording, style, optional clarity, preference, edge-case overfitting, or nice-to-have improvement.
Only report Blocking or Material issues by default.
Mention Minor issues only if they reveal a real execution risk.
Ignore pure preferences unless they affect correctness or execution.
If there are no Blocking or Material issues, say exactly:
Good enough to implement.
Return only:
1. Verdict: Blocked, Needs tightening, or Good enough to implement
2. Numbered Blocking/Material criticisms
3. Concise suggested fixes
Plan to criticize:
<PASTE_PLAN_HERE>
```

## Improvement Strategy

After each criticizer result:

- Make a decision table or concise list.
- Mark each criticism as valid, partly valid, invalid, or preference-only.
- Explain only the important decisions.
- Update the plan directly.
- Do not blindly accept criticism that expands scope beyond the user’s goal.
- Preserve explicit cut lines and deferred work.
- Prefer concrete API, validation, test, and verification wording.
- Do not chase exhaustive perfection; the goal is an executable, low-risk plan.

## Stop Condition

Stop when:

- A fresh criticizer returns `Good enough to implement.`
- The criticizer reports only Minor, preference-only, duplicated, speculative, or non-actionable feedback.
- Two criticizer rounds have completed without finding a new Blocking issue.
If the loop repeats the same issue:
- Tighten the plan once.
- If it recurs without new substance, call it resolved or preference-only and explain why.

Final Output

Return:
- The final implementation plan.
- A short convergence note.
- Any residual risks or known deferrals.
