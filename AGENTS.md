# Dayleft repository operating contract

## Communication and request modes

Communicate in English. Give constructive technical and product criticism. Answer/explain,
inspect, review/audit, diagnose, research, plan, recommend, and status requests are read-only.
Do not run project code, tests, builds, generators, or change files/Git/external state for those
requests. Questions about hypothetical fixes do not authorize implementation. Ambiguity defaults
to read-only. Explicit implement/fix/setup instructions authorize bounded local changes and
proportionate validation; publication and other external actions need explicit authority.

## Product and documentation ownership

Read [SPEC.md](SPEC.md), [SCOPE.md](SCOPE.md), [ROADMAP.md](ROADMAP.md),
[docs/README.md](docs/README.md), and the relevant implemented logic before editing.
The current app is a sample preview; do not describe it as a completed live timer.
Keep the timer independent of connections. Slopometer and task providers are after MVP.
SPEC, SCOPE, and the approved image are product contracts: consult the user for changes to
agreed boundaries unless the current request already explicitly authorizes that change.
Update owning logic and the consolidated timer manual guide with behavioral changes.
Research/roadmap describe proposals; they cannot silently override implemented logic.

## Git and delivery

This new repository is bootstrapped on `codex/bootstrap`; its validated initial commit seeds
the public `main` branch. This first publication is not a merge of existing branches.
After bootstrap, `main` is the integration branch. Keep its checkout clean and never edit it
directly. Inspect Git state, remote synchronization, dirty/ignored files and worktrees first.
Reuse a suitable task-owned checkout or create an isolated worktree on
`codex/<short-kebab-case-task>` from verified latest `origin/main`. Preserve unrelated work;
do not stash/reset/clean/overwrite it. Never commit credentials, local signing material, caches,
or unintended generated files. Keep PRs scoped to one deployable concern.

Do not push, create/update a PR, merge, release, change access, deploy, or publish binaries
without matching explicit authority. Public source creation does not imply later publication
authority. Use the available file-pr skill when PR publication is explicitly requested.
Preserve the chat title unless the user requests a rename. No production target is configured.

## Processes and validation

Before CPU-intensive work, inspect current processes and their working directories for an
equivalent command. Reuse/wait; never launch a duplicate retry. At most one intensive validation
per worktree; `scripts/dev.sh` enforces a validation lock and `make` is not parallelized.
Never use watch mode unless requested. Keep/poll the original session until completion.
Investigate targeted tests after 3 minutes, full suites/builds after 15, UI suites after 20.
Inspect PID/PPID, cwd, elapsed time, CPU, memory growth, and output before deciding a run is
stalled. A threshold or high CPU alone does not prove failure. Before retrying, capture
diagnostics and confirm the old tree exited. Only stop exact task-owned process trees;
clean up owned runs when interrupted. Remove a stale validation lock only after its recorded
PID has exited. Do not use broad destructive cleanup.

Use `make check` before calling a change locally validated. Its registry, source paths,
duration estimates, CPU classification, prerequisites, and human-owned commands are in
[docs/development.md](docs/development.md). Do not invent alternative gates.
CI and local checks are distinct; manual/provider/signing/release gates remain distinct too.

## Toolchain, UI, and collaboration

Read the versioned [tool references](docs/development.md#toolchain-and-sources) for changes to
project generation, build scripts, or CI. `project.yml` and `Package.swift` are authoritative;
the generated Xcode project is ignored. No third-party runtime dependencies are present.

Prefer source/CLI/API inspection. Agent-operated UI testing runs only when explicitly requested.
Human testing owns native menu bar behavior, visual fidelity, accessibility, monitors/Spaces,
sleep/wake, and login launch; track it under [testing/MANUAL TO-DO](testing/MANUAL%20TO-DO/README.md).

Use additional agents only when the user's request, applicable instructions, and runtime policy
allow it and independent scopes warrant it. The primary agent owns shared contracts,
dependencies, combined validation, and the merge recommendation. Each implementation agent
owns one branch/worktree, bounded files/domain, checks, docs, publication authority, and handoff.
Never race on shared files. Verify reports against source/evidence. A batch checkpoint checks
the intended combined tree and exact PR heads; it does not grant merge authority.
