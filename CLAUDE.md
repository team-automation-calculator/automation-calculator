# CLAUDE.md

@AGENTS.md

## Session start

Two SessionStart hooks in `.claude/settings.json` keep the knowledge graph (`AGENTS.md`, "Knowledge graph") usable without a step from you:

- `./go graphify-seed --quiet` — in a git worktree with no `graphify-out/`, copies the main checkout's graph and refreshes its code layer to the branch. Without it the `/graphify` skill finds no `graphify-out/graph.json` in a new worktree and starts a full build there. Silent in the main checkout, in a worktree already seeded, and when the main checkout has no graph.
- `./go graphify-status --brief` — prints one `graphify:` line when the graph is behind `HEAD` or documents wait for the LLM pass. Follow it (`./go graphify-update`) before the first graph query. Silent when the graph is current or absent.

Neither calls an LLM, and neither does anything in a cloud or CI session (`CLAUDE_CODE_REMOTE`, `CI`, `GITHUB_ACTIONS`). `/graphify .` and `/graphify --update` spend tokens: run them only when asked, in the main checkout on `main`, never in a worktree.
