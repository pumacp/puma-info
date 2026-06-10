# Contributing to puma-info

This is the development workflow for puma-info. It applies to every change.
Repository-wide hard rules (isolation, reproducibility, content hygiene, the
AI-use log) are defined in [`AGENTS.md`](AGENTS.md) and
[`docs/constitution.md`](docs/constitution.md) and are not repeated here.

## Branch model

- All work happens on a **short-lived branch off `main`**, named by type:
  `feat/…`, `fix/…`, `docs/…`, `chore/…`, `refactor/…`.
- **Never commit directly to `main`.** `main` only advances through the merge
  procedure below.

## Commit identity

Every commit, push and any remote change is authored **solely by the project
user**:

```
pumacp <266590835+pumacp@users.noreply.github.com>
```

- **No co-authors, no assistant/tool trailers, no personal usernames or emails.**
- Make each commit with the identity pinned explicitly:

```bash
git -c user.name="pumacp" -c user.email="266590835+pumacp@users.noreply.github.com" \
    commit -m "…"
```

## Commit messages

- Concise, **English**, imperative mood (e.g. "Add", "Fix", "Document").
- **No trailers.**
- The subject must describe the change **accurately** — it must match what the
  commit actually contains.
- **Atomic commits:** one logical change per commit (and per branch/PR).

## Merge procedure (CLI-local, fast-forward only)

Never merge through the GitHub web UI or API — that rewrites the committer and
breaks the single-author guarantee. Merge from the command line, fast-forward
only:

```bash
git checkout main
git merge --ff-only <branch>
git push origin main
git branch -d <branch>
```

Keep the branch rebased on `main` so the merge stays fast-forward.

## Gates for risky work

- **Design before implement** — for non-trivial changes, write the design first.
- **Back up before modifying** irreplaceable source material.
- **Verify by real execution**, not a dry run, before committing — a stubbed or
  dry run does not prove a binary exists or a filter behaves.
- When adding a flag or target, keep existing behaviour **byte-identical by
  default**, and prove it rather than assuming it.

## Public hygiene

This is a **public** repository.

- **English only** in versioned sources. Localized text belongs only in output
  artifacts (subtitle tracks, localized descriptions), never in source files.
- **No personal identifiers** (usernames, emails) and **no machine-local absolute
  paths** in tracked files.
- Keep private working material out of version control: the `_private/`
  directory is **gitignored** and is never published.
