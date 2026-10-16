# Contributing

Read [AGENTS.md](AGENTS.md), [SCOPE.md](SCOPE.md), and [the documentation index](docs/README.md)
before changing behavior. Use an isolated `codex/<short-task>` branch/worktree from current
`origin/main` after the initial repository publication.

Run `make setup`, then `make check`. Use `make format` intentionally before validation. Keep
Swift package and Xcode project definitions consistent; regenerate rather than editing the
ignored Xcode project. Read the pinned-tool references in [development.md](docs/development.md).

Changes to timing semantics update [the logic guide](docs/logic/timing.md), focused tests, and
[the consolidated timer manual guide](testing/MANUAL%20TO-DO/timer.md) together. UI behavior,
scope changes, and provider integrations need the corresponding product-document updates.

Public repository visibility is not approval to push arbitrary changes, file PRs, merge,
publish binaries, or deploy. Ask for those actions when not already explicitly authorized.
