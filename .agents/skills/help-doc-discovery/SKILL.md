---
name: help-doc-discovery
description: >-
  Analyze operately git history and code changes to build a documentation backlog.
  Use when reviewing recent commits, a release, or a feature branch to find
  user-facing changes that need help-center coverage. Produces terse technical
  change notes for a downstream writing agent — not end-user help copy. Do not
  use for writing or publishing help pages; that belongs in the website repo.
---

# Help Doc Discovery

You are **agent 1** in a two-agent documentation pipeline:

1. **This skill (operately repo)** — parse code changes, infer user-visible
   behavior, produce a terse technical backlog of what to document.
2. **Writing agent (website repo)** — turn that backlog into end-user help pages
   using writing guidelines in `website/docs/help-center/`.

Do not draft MDX, tune prose for search engines, or edit the website repo.
Your output is input for agent 2.

## Scope

**In scope:**

- Git history and diffs in this repo (`operately`)
- User-visible UI changes in `app/assets/js/`, `turboui/src/`, and related routes
- New or changed permissions, settings, notifications, and activity-feed events
  when they affect what users see or can do
- Identifying whether each item needs a **new page**, **update to an existing
  page**, or **no doc action**
- Exact UI labels, navigation paths, and flows inferred from frontend source

**Out of scope:**

- Writing help copy or choosing final page titles/descriptions
- Editing `website/` or any MDX files
- Backend implementation details unless needed to locate the UI entry point
- API reference pages under `help/api/` (auto-generated on deploy — note the
  change but do not add manual doc tasks for endpoint reference)

For path filters, diff commands, code-reading heuristics, and the output
template, read [reference.md](reference.md).

## Workflow

### 1. Define the change window

Establish what commits to analyze. Prefer an explicit range from the user:

| Input | Git command |
| ----- | ----------- |
| Since last release tag | `git log <tag>..HEAD --oneline` |
| Between two refs | `git log <base>..<head> --oneline` |
| Last N commits on branch | `git log -n <N> --oneline` |
| Since date | `git log --since=<date> --oneline` |

Record the resolved range (`<base>..<head>` or commit SHAs) in the output.

### 2. Collect user-facing diffs

Run path-scoped diffs and stats. Start with the paths in
[reference.md — User-facing paths](reference.md#user-facing-paths).

```bash
git diff <base>..<head> --stat -- app/assets/js/ turboui/src/
git log <base>..<head> --oneline -- app/assets/js/ turboui/src/
```

Group related commits by feature area (goals, spaces, kanban, permissions, etc.).
Skip commits that only touch tests, CI, deps, or internal refactors with no UI
impact.

### 3. Triage each change cluster

For each cluster, decide:

| Verdict | When |
| ------- | ---- |
| **New doc** | New user-facing capability with no matching help page |
| **Update doc** | Existing flow, labels, permissions, or screens changed |
| **No doc action** | Internal-only; bugfix with no user-visible behavior change; test/CI only |
| **API auto** | External API surface changed — CI syncs `help/api/`; no manual page |

When unsure, read the changed components and feature tests to confirm what users
actually see. Prefer `app/test/features/` and `*.spec.ts(x)` to validate flows.

### 4. Infer behavior from code

For every item that needs documentation, extract facts from source — not from
imagination:

- Navigation path (menus, tabs, links, keyboard shortcuts if surfaced in UI)
- Trigger controls (button/menu labels, exact casing)
- Form fields, validation messages, empty states, success/error toasts
- Permission gates visible in the UI
- Preconditions (e.g. must be space admin)
- Post-action effects (what appears in activity feed, notifications)

Read `app/assets/js/pages/` and `app/assets/js/features/` first. Follow imports
into `turboui/src/` when needed. Use backend code only to find which page renders
a feature.

### 5. Map to existing help coverage

Search the website repo for pages that may already cover the feature:

```bash
# from operately repo, if website is a sibling checkout
rg -l "<feature-keyword>" ../website/src/content/docs/help/
```

List likely slugs to update (e.g. `create-goal`, `kanban-board-add-task`) or
state **no existing page**. Do not read or apply writing style from those files —
only identify coverage gaps and update targets.

### 6. Emit the backlog

Write the report using the template in
[reference.md — Output format](reference.md#output-format). Keep language terse
and technical. Agent 2 will rewrite for non-technical readers.

Each item must include enough facts to draft a page without re-reading the diff:
labels, paths, behavior, permissions, and pointers to source files.

### 7. Hand off

End the report with a short **handoff** block:

- Git range analyzed
- Count of new / update / no-action / API-auto items
- Reminder that agent 2 should use `website/docs/help-center/` guidelines

Save or paste the backlog where the pipeline expects it (issue comment, PR
description, or file path the user specifies).

## Definition of Done

- [ ] Change window is explicit (`<base>..<head>` or equivalent)
- [ ] Diffs were filtered to user-facing paths; internal-only commits excluded or listed under "No doc action"
- [ ] Every backlog item has a verdict (new / update / no doc action / API auto)
- [ ] UI labels and navigation paths are quoted from source, not paraphrased
- [ ] Existing help slugs are noted when an update is likely
- [ ] Output uses the reference template; no MDX or end-user prose drafted
- [ ] Handoff block points agent 2 at the website repo writing guidelines
