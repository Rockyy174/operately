# Help Doc Discovery Reference

This document expands on [SKILL.md](SKILL.md). Use it for git workflows, code
tracing, classification heuristics, and the backlog output schema.

## Pipeline context

```
operately repo (this repo)          website repo (sibling)
─────────────────────────          ───────────────────────
agent 1: discovery brief    →      agent 2: user-facing MDX
(help-doc-discovery skill)         (website writing guidelines)
```

Agent 1 never writes MDX. Agent 2 never needs to re-read git history if the
brief is complete.

## Git analysis

### Common scopes

| Request | Git approach |
| ------- | ------------ |
| Since last release | `git log v1.2.0..HEAD --oneline -- app/assets/js/` |
| Last N weeks | `git log --since="8 weeks ago" --oneline -- app/assets/js/` |
| Single PR / merge | `git log --oneline main..branch` or PR commit SHAs |
| One commit | `git show --stat <sha>` then `git show <sha>` |
| Compare tags | `git diff v1.1.0..v1.2.0 --stat -- app/assets/js/` |

### Useful commands

```bash
# Commits touching frontend (adjust paths as needed)
git log --oneline <range> -- app/assets/js/ app/test/features/ turboui/src/

# Files changed with line counts
git diff --stat <base>..<head> -- app/assets/js/ turboui/src/

# Find commits mentioning a feature keyword
git log --oneline <range> --grep="billing" -i

# See what a commit actually changed
git show --stat <sha>
git show <sha> -- app/assets/js/

# List new files in range (often new pages or components)
git diff --name-status <base>..<head> -- app/assets/js/pages/

# Authors / PR grouping (manual follow-up on related SHAs)
git log --oneline --format="%h %s" <range> -- app/assets/js/
```

### Grouping commits

Merge related SHAs before writing briefs:

- Same PR or `[#1234]` in message
- Same feature prefix (`feat: billing`, `fix: kanban`)
- Touches the same page directory within a few days
- Sequential commits by one author on one component

One backlog item can reference multiple commits. Do not create one item per
commit unless each commit is an independent user-facing change.

## Code tracing

### Decision tree

```
diff touches app/assets/js/ or turboui/?
├─ yes → read page/feature components → extract UI facts → brief
├─ only app/lib/ → find frontend entry (grep route, page import, feature name)
│   ├─ UI change found → brief
│   └─ no UI change → no_doc_needed
└─ only tests/config/ci → no_doc_needed
```

### Where to look

| Area | Path | What to extract |
| ---- | ---- | --------------- |
| Pages | `app/assets/js/pages/` | Routes, tabs, nav items, page-level actions |
| Features | `app/assets/js/features/` | Modals, wizards, forms, activity feed UI |
| Shared UI | `turboui/src/` | Billing banners, limit notices, shared modals |
| Routes | `app/assets/js/routes/` or router config | New URLs, renamed paths |
| Feature tests | `app/test/features/` | Step order, visible labels, permission scenarios |
| Component tests | `app/assets/js/**/*.spec.ts` | Exact copy, disabled states |

### Backend as a locator only

When the diff is mostly `app/lib/`:

1. Note the operation, context, or schema name from the diff
2. Grep frontend for that feature: `rg "FeatureName" app/assets/js/`
3. Read the page/component that calls the API or renders the result
4. Document only what that UI exposes

Ignore for the brief: Ecto schemas, GraphQL types, serializers, notification
routing, activity content handlers (unless they add a visible feed line users
need help understanding).

### Activity system signal

A new directory under `app/assets/js/features/activities/` often means a new
feed event string — usually **not** a standalone help page unless the activity
represents a major feature users act on. Mention it in a related feature brief
if the feed text is user-confusing.

### Permission and billing signals

| Signal in code | Likely doc need |
| -------------- | --------------- |
| New `can_*` check in frontend | Permission or access reference update |
| Billing gate / banner component | Billing or limits how-to or overview |
| Read-only UI branch | Document who sees what |
| Limit exceeded modal | New troubleshooting or upgrade path |

## Classification

### `action` values

| Value | When |
| ----- | ---- |
| `new_doc` | New user task or concept with no adequate existing page |
| `update_doc` | Existing page is incomplete or now wrong |
| `verify_doc` | Existing page may still be accurate; writer should confirm |
| `no_doc_needed` | Change is internal or too minor for help center |

### `area` values

Align with website help sections when possible (see table below). Use the
closest match; add a short note if none fit.

| Area | Typical triggers |
| ---- | ---------------- |
| Account management | Login, profile, password, appearance |
| Global Search | Search UI |
| User profiles | Profile pages, assigned work |
| Work maps | Hierarchy views |
| Permissions & Access | Access levels, privacy, gates |
| Goal tracking | Goals, targets, check-ins |
| Project management | Projects, milestones, tasks |
| Spaces | Space CRUD, members, tools |
| Kanban board | Board views, columns, cards |
| Discussions | Posts, replies, reactions |
| Documents & Files | Docs, files, exports |
| Review | Champion/reviewer flows |
| People | Members, org chart |
| Company administration | Org settings, invites, import/export |
| Notifications | Email and in-app notification settings |
| Billing | Plans, limits, upgrades, payment |
| Self-hosted installations | Install, update, email config |
| CLI | CLI commands (user-facing) |

### Confidence

| Level | Meaning |
| ----- | ------- |
| `high` | UI diff and tests clearly show user-visible change |
| `medium` | Behavior inferred from partial UI diff or backend trigger |
| `low` | Possible user impact; needs writer verification or product input |

## Existing documentation lookup

Website repo path (sibling): `../website/src/content/docs/help/`

```bash
# Find pages mentioning a feature
rg -l "billing" ../website/src/content/docs/help/

# List all help slugs
ls ../website/src/content/docs/help/
```

Sidebar config (`../website/src/config/helpCenter.js`) helps confirm area grouping
but slug search is the primary mapping tool.

**Do not edit** anything under `help/api/` — those files are CI-generated.

## Output format

Deliver a single markdown document (or structured equivalent) with this shape.

### Header

```markdown
# Documentation backlog

## Scope
- **Range:** `v1.4.0..abc1234` (or description of window)
- **Analyzed commits:** 47
- **Paths:** `app/assets/js/`, `turboui/src/`, `app/test/features/`
- **Generated:** 2026-06-09
```

### Item template

```markdown
### DOC-001: Billing page gated by can_manage_billing

- **action:** update_doc
- **area:** Billing
- **confidence:** high
- **commits:** e5b9048cc, 667e59aab
- **files:**
  - `app/assets/js/pages/Company/BillingPage.tsx`
  - `turboui/src/billing/BillingPlanCard.tsx`
- **what_changed:** Billing management UI and CTAs render only when
  `can_manage_billing` is true; other members see read-only plan summary.
- **user_visible_behavior:**
  - Users without permission: no edit/upgrade actions; plan details view only.
  - Users with permission: full billing management as before.
- **ui_surface:**
  - **entry_points:** Company → **Billing** (sidebar or settings nav — verify in BillingPage)
  - **labels:** (quote exact strings from components)
  - **flow_steps:** 1) Open Billing … 2) …
- **existing_docs:** `/help/manage-billing` (likely needs permission section)
- **suggested_doc_focus:** Document who can manage billing vs view-only access.
- **open_questions:** none
```

### Numbering and granularity

- One item = one documentation unit (one task or one concept page)
- Split combined PRs into separate items when users have distinct tasks
- Merge tiny label-only tweaks into a parent item's `what_changed` bullet

### `no_doc_needed` section

List excluded change groups so the pipeline audit trail is clear:

```markdown
## Excluded (no_doc_needed)

| Commits | Reason |
| ------- | ------ |
| `a1b2c3d` | Test-only: added Wallaby coverage for existing flow |
| `d4e5f6g` | Refactor: moved billing utils; no UI string changes |
```

## Example brief (good vs bad)

**Good** — technical, traceable, actionable for agent 2:

```markdown
### DOC-003: Configurable task reminders

- **action:** new_doc
- **area:** Project management
- **confidence:** high
- **commits:** f0239cc29
- **files:** `app/assets/js/features/tasks/ReminderSettings.tsx`, …
- **what_changed:** Task reminder schedule is configurable per task (new settings UI).
- **user_visible_behavior:** User opens task → **Reminders** section → sets interval/conditions.
- **ui_surface:**
  - **labels:** "Reminders", "Add reminder", … (exact strings from ReminderSettings.tsx)
- **existing_docs:** none
- **suggested_doc_focus:** How to add and edit task reminders on a task.
```

**Bad** — reads like finished help copy (agent 2's job):

```markdown
### Task reminders

Task reminders help you stay on top of deadlines. In this guide, you'll learn
how to easily configure reminders so you never miss an important due date.
```

## Signals cheat sheet

| Diff pattern | Start reading |
| ------------ | ------------- |
| New file in `pages/` | Page component + route registration |
| New `features/*` modal | Modal + parent page that opens it |
| `turboui` billing/limit | All pages importing the component |
| `test/features/*` added/changed | Test steps → user flow outline |
| Permission enum or `can_*` in JS | Pages checking that permission |
| Renamed button string | Grep old label in website docs for `update_doc` |
| Deleted page/component | `update_doc` or deprecation note for writer |

## Handoff checklist

Before passing to the writing agent:

- [ ] Every `high`/`medium` item has exact UI labels from source
- [ ] `existing_docs` checked against website repo (or marked `unavailable`)
- [ ] `suggested_doc_focus` is one clear sentence, not a draft paragraph
- [ ] Excluded changes are listed with reasons
- [ ] No MDX, Starlight components, or sidebar instructions included
