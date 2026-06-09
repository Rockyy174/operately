# Help Doc Discovery Reference

Expands on [SKILL.md](SKILL.md). Use this file for git commands, path filters,
code-reading heuristics, and the backlog output template.

## Pipeline context

| Agent | Repo | Role |
| ----- | ---- | ---- |
| Agent 1 (this skill) | `operately` | Parse git history → terse technical backlog |
| Agent 2 | `website` | Turn backlog into end-user help pages using `website/docs/help-center/` |

Published help center: [operately.com/help](https://operately.com/help)

Website paths (for coverage lookup only — do not write docs here):

| What | Path |
| ---- | ---- |
| Help content | `website/src/content/docs/help/` |
| Sidebar config | `website/src/config/helpCenter.js` |
| Writing guidelines | `website/docs/help-center/README.md` |
| AI drafting tips | `website/docs/help-center/ai-tips.md` |
| API docs (auto-generated) | `website/src/content/docs/help/api/` |

## User-facing paths

Prioritize these paths when scanning diffs. Changes here often need doc action.

| Path | What changes imply |
| ---- | ------------------ |
| `app/assets/js/pages/` | New routes, screens, navigation |
| `app/assets/js/features/` | Feature UI, modals, forms, activity handlers |
| `app/assets/js/components/` | Shared app components visible in product UI |
| `turboui/src/` | Shared UI primitives (when user-visible) |
| `app/assets/js/routes*` or router config | New URLs users can visit |
| `app/lib/operately/activities/content/` | New activity types (feed copy) |
| `app/lib/operately/permissions/` | Permission model changes (check UI impact) |
| `app/test/features/` | New E2E flows — useful for inferring steps, not doc content |

Usually **no doc action** (unless paired with UI changes above):

| Path | Why skip |
| ---- | -------- |
| `app/lib/operately/operations/` | Business logic — read only to find UI entry |
| `app/lib/operately_web/api/` | API handlers — reference docs auto-sync |
| `app/priv/repo/migrations/` | Schema only |
| `.github/`, `scripts/`, `docker/` | Tooling |
| `*_test.exs`, `*.spec.ts(x)` alone | Tests without production code changes |

## Git analysis commands

Replace `<base>` and `<head>` with tags, branches, or SHAs.

```bash
# Overview
git log <base>..<head> --oneline
git diff <base>..<head> --stat

# User-facing files only
git diff <base>..<head> --stat -- app/assets/js/ turboui/src/
git log <base>..<head> --oneline -- app/assets/js/ turboui/src/

# See what changed in a specific area
git diff <base>..<head> -- app/assets/js/pages/Goals/
git diff <base>..<head> -- app/assets/js/features/kanban/

# Find commits by message keyword
git log <base>..<head> --oneline --grep="kanban" -i

# List new files (often new screens or components)
git diff <base>..<head> --diff-filter=A --name-only -- app/assets/js/
```

When the user gives a PR number, use `origin/main..<branch>` or the PR's base/head
SHAs.

## Triage heuristics

### Signals that need a **new** help page

- New page component under `app/assets/js/pages/` with a distinct user task
- New modal/wizard for a capability not covered by existing docs
- New product area (new sidebar section, new settings screen)
- New permission level or access control surfaced in UI

### Signals that need an **update** to existing docs

- Button, menu, or field labels renamed
- Steps reordered or entry path added/removed
- Permission requirements changed in UI
- Feature removed, hidden behind flag, or moved to a different screen
- Copy in empty states, errors, or confirmations changed materially

### Signals for **no doc action**

- Refactor with identical UI (grep for label strings before/after)
- Performance, caching, or backend-only bugfix
- Dependency bumps, formatting, CI
- Internal rename of modules with no route or label change

### Signals for **API auto** (note only)

- Changes under `app/lib/operately_web/api/` or `app/lib/operately/api_docs/`
- CI publishes to `website/.../help/api/` on deploy — no manual backlog item for
  endpoint reference pages unless the user explicitly wants a product how-to about
  API usage (that would be a **new** user-facing page, not reference sync)

## Code-reading workflow

For each triaged cluster:

1. **Identify the entry point** — page route, nav item, or parent feature module
2. **Trace the happy path** — follow click handlers, modals, and form submit
3. **Collect exact strings** — button text, titles, placeholders, toast messages
4. **Note guards** — `disabled`, permission checks, empty states, feature flags
5. **Check side effects** — activity handler added? notification? email?
6. **Cross-check tests** — `app/test/features/*.exs` or `*.spec.ts` for step order

### Where to find UI facts

| Fact | Where to look |
| ---- | ------------- |
| Page layout and tabs | `app/assets/js/pages/**` |
| Feature-specific flows | `app/assets/js/features/**` |
| Reusable controls | `turboui/src/**` |
| Route definitions | search `routes` / router files in `app/assets/js/` |
| Activity feed text | `app/assets/js/features/activities/**/index.tsx` |
| Permission UI | search "permission", "access", "Full Access" in feature folders |

### Inferring navigation paths

Build paths from actual UI structure:

```
Top nav **+ New** → **Goal** → modal fields → **Add Goal**
Space → **Kanban** tab → column **⋯** menu → **Rename column**
```

Use `→` between steps. Bold exact labels from source.

## Mapping to help center sections

Tag each backlog item with a **help section** to speed agent 2's sidebar placement.
Sections mirror `website/src/config/helpCenter.js`:

| Section | Typical features |
| ------- | ---------------- |
| Meet Operately | Onboarding, tour, product intro |
| Account management | Login, profile, password, appearance |
| Global Search | Search |
| User profiles | Personal tasks, activity, relationships |
| Work maps | Hierarchy views |
| Permissions & Access | Access levels, inheritance |
| Goal tracking | Goals, targets, check-ins |
| Project management | Projects, milestones, tasks |
| Spaces | Spaces, members, tools |
| Kanban board | Board views, columns, cards |
| Discussions | Posts, replies |
| Documents & Files | Docs, files, exports |
| Review | Champion/reviewer workflows |
| People | Members, org chart |
| Company administration | Org settings, invites, import/export |
| Notifications | Email and in-app notification settings |
| Self-hosted installations | Install, update, email config |
| CLI | CLI usage |

## Output format

Use this structure. Adjust sections only if the user requests a different schema.

```markdown
# Help documentation backlog

**Range:** `<base>..<head>` (<N> commits)
**Analyzed:** YYYY-MM-DD
**Agent:** help-doc-discovery (operately)

## Summary

| Verdict | Count |
| ------- | ----- |
| New doc | |
| Update doc | |
| No doc action | |
| API auto | |

## New documentation

### [NEW-1] Short technical title

- **Help section:** Kanban board
- **Suggested coverage:** new how-to (agent 2 chooses slug/title)
- **Commits:** `abc1234`, `def5678`
- **Source files:**
  - `app/assets/js/features/kanban/ColumnMenu.tsx`
  - `app/assets/js/pages/SpacePage/KanbanTab.tsx`
- **User-visible behavior:**
  - Column header shows **⋯** menu with **Rename column** and **Delete column**
  - Rename opens inline edit; Enter saves, Escape cancels
  - Delete requires confirmation dialog **Delete this column?**
- **Navigation:** Space → **Kanban** → column header **⋯**
- **Permissions:** Space **Edit Access** or higher (from `canEditSpace` guard in …)
- **Related existing docs:** none found / possibly related: `kanban-board-add-task`
- **Notes:** Deletes column only when empty; otherwise toast **Remove all tasks first**

## Updates to existing documentation

### [UPD-1] Short technical title

- **Help section:** Goal tracking
- **Likely pages to update:** `create-goal`, `set-goal-privacy`
- **Commits:** `fedcba9`
- **What changed:** …
- **Before → after (UI):** **Add Goal** button moved from toolbar to **+ New** menu
- **Source files:** …

## API auto (no manual reference doc)

- `app/lib/operately_web/api/goals/update.ex` — new `description` input; CI syncs API docs

## No doc action

| Commit | Reason |
| ------ | ------ |
| `111aaa` | Refactor Kanban drag hook; no label or route changes |
| `222bbb` | CI workflow only |

## Handoff for agent 2

- **Input:** this backlog
- **Repo:** `website`
- **Guidelines:** `website/docs/help-center/README.md`, `ai-tips.md`
- **Do not edit:** `website/src/content/docs/help/api/` (generated)
```

### Item priority (optional)

When the user wants prioritization, add **P0 / P1 / P2**:

| Priority | Criteria |
| -------- | -------- |
| P0 | New capability, permission change, or breaking UX change |
| P1 | Notable UX improvement users will look for in help |
| P2 | Minor label move, secondary entry path, edge-case clarification |

## Existing doc lookup

From operately, if `website` is checked out as a sibling:

```bash
ls ../website/src/content/docs/help/
rg -l "kanban" ../website/src/content/docs/help/
rg -l "Rename column" ../website/src/content/docs/help/
```

Match by feature keywords, slugs in `helpCenter.js`, and titles in frontmatter.
List **likely slugs** — agent 2 confirms and applies writing guidelines.

## Common mistakes to avoid

- Drafting end-user prose or MDX — that is agent 2's job
- Paraphrasing UI labels instead of quoting source strings
- Creating doc tasks for every commit instead of clustering by feature
- Documenting GraphQL, Elixir modules, or DB schema in the backlog (keep UI facts only)
- Adding manual API reference tasks for handler changes (CI handles sync)
- Skipping the handoff block and website guideline pointers
- Analyzing the whole repo diff without path filters (noisy, slow)
