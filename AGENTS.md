# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Development Commands

All commands run via the `./go` script (a Ruby dispatcher into `scripts/`):

```bash
./go init              # First-time setup: build images and run db setup
./go start             # Start dev server at http://localhost:3001/
./go test              # Run full RSpec suite in Docker
./go compile           # Check that every tracked Ruby file parses (ruby -c); takes file paths too
./go lint              # Run the compile check, then RuboCop, in Docker
./go format            # Apply RuboCop safe autocorrections
./go validate          # lint, then test: what CI checks; changes nothing
./go shell             # Open a shell in the dev container
./go stop              # Stop containers
./go restart           # Stop and restart the dev environment
./go clean             # Remove all containers, images, volumes
./go build             # Build Docker images locally (required after Gemfile changes); does not push
./go push              # Push built images to Docker Hub; separate from build
./go db dev            # Connect to PostgreSQL with psql
./go logs              # Tail container logs
./go graphify-status   # How far the knowledge graph is behind HEAD (--brief: one line, only when behind)
./go graphify-update   # Refresh the knowledge graph's code layer to HEAD: AST only, no LLM, no Docker
./go graphify-seed     # In a git worktree: copy the main checkout's graph, refresh it to the branch
```

**Run a single test** from inside `./go shell`:
```bash
rspec spec/models/solution_spec.rb
rspec spec/models/solution_spec.rb:42
```

Or from the host:
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml run --rm dev rspec spec/path/to/file_spec.rb
```

**Before committing:** Run `./go lint` and fix every syntax error and RuboCop offense (`./go format` applies the safe autocorrections). CI runs lint and will fail on any offense, including in scripts and config files.

**Troubleshooting:**
- After updating the Gemfile, run `./go build` before `./go test` or `./go start`.
- If `./go start` exits with "A server is already running", run `./go shell` then `rm /usr/src/app/tmp/pids/server.pid`.
- When running more than one checkout (e.g. several git worktrees) at once, `cp docker-compose.local.example.yml docker-compose.local.yml` in each; it drops the fixed `db` container name and host port 5434 that make the second checkout's `docker compose run` fail. `./go` picks the file up automatically and it is gitignored.
- If the `db` container exits right after `./go init` or `./go start` with `Error: in 18+, these Docker images are configured to store database data ...` (or `database files are incompatible with server`), this checkout's `postgres` volume still holds a PostgreSQL 16 data directory from before the `postgres:18-alpine` bump. Dev data is disposable and nothing is migrated: drop the volume with `docker compose down --volumes` and run `./go init` again. `./go clean` also works but removes every image as well, so the next `./go init` rebuilds from scratch. No `./go` command drops only the volume.

## Architecture

### Two Parallel Interfaces

The app exposes the same domain through two completely separate stacks:

1. **HTML web interface** — Haml views, Bootstrap 4, Rails form submissions, Devise session authentication. Entry point: `AutomationScenariosController` (`app/controllers/automation_scenarios_controller.rb`).
2. **JSON API** — `app/controllers/api/v1/`, JWT token authentication via `HTTP_ACCESS_TOKEN` header, ActiveModel Serializers for responses. Routes are version-gated by a `Constraint` class (`app/lib/constraint.rb`): the version lives in the `Accept` header (`application/json; version=1`), not the path. Paths have no `/v1` segment — e.g. `GET /api` (root), `POST /api/visitor`, `GET /api/automation_scenarios/:id/intersections`. A request without that header (or to `/api/v1/...`) gets a 404.

These are not coupled — changing one doesn't affect the other.

### Visitor Pattern (Polymorphic Owner)

`AutomationScenario` belongs to a polymorphic `owner` — either a `User` or a `Visitor`. This lets unauthenticated users try the app immediately:

- On first visit, a `Visitor` record is created (with a random UUID and the client's IP) and stored in the session (`session[:visitor_id]`).
- The `Visitable` concern (`app/controllers/concerns/visitable.rb`) provides `current_visitor` and `current_user_or_visitor` to all controllers.
- When a visitor signs up, their scenarios are not automatically migrated to the new `User` — they start fresh.

In the API, `current_member` resolves to whichever of `current_user` or `current_visitor` is present from the JWT payload.

### Break-Even Calculation

The core math is in `SolutionPair` (`app/services/solution_pair.rb`):

- `Solution#cost_at(n)` = `initial_cost + (iteration_cost * n)` — a linear cost function.
- `SolutionPair#intersection_iteration` solves for the crossing point algebraically: `(initial_cost₁ − initial_cost₂) / (iteration_cost₂ − iteration_cost₁)`.
- `AutomationScenario#solutions_combinations` returns all `SolutionPair`s from `.combination(2)` on persisted solutions.
- `SolutionTuple` (`app/services/solution_tuple.rb`) sorts solutions by their total cost at the scenario's `iteration_count`.

### Frontend Chart Data Flow

The scenario show page uses a server-side-to-client-side data handoff rather than an API call:

1. The Haml view embeds a hidden `#scenarioData` element containing the full JSON from `AutomationScenarioForGraphSerializer`.
2. On `turbolinks:load`, `automation_scenarios.coffee` reads that JSON, builds Plotly.js trace objects, and renders the chart into `#solutionsChart`.
3. Intersection points are pre-computed server-side in the serializer (`solutions_combinations.map(&:intersection_point_within_boundaries)`) and rendered as scatter markers.

### JWT Authentication (API)

`JwtTokenService` (`app/services/jwt_token_service.rb`) encodes/decodes tokens using `Rails.application.secret_key_base`. The payload contains either `user_id` or `visitor_id`. Token expiry is controlled by `Settings.api_session_duration` (minutes, from `config/settings.yml`).

### Key Configuration

- `config/settings.yml` — app-level config accessed via `Settings.*` (the `config` gem)
- `config/cache.yml` — Solid Cache, the production `Rails.cache` (`config.cache_store = :solid_cache_store`). Entries live in the `solid_cache_entries` table of the primary database, so the `rate_limit` counters are shared by every pod and survive a restart. Development and test stay on `:null_store`, so `rate_limit` never throttles there.
- `RAILS_LOG_LEVEL` — production log level (`config/environments/production.rb`); defaults to `debug`. Log through `Rails.logger` / `logger`, never `puts`.
- Security events (sign-in, sign-up, password and email changes, rejected credentials, OAuth failures, rate-limit hits) are logged as `Event: key=value … ip=…`: `warn` for a rejection, `info` for a success. Name people by `user=<id>` / `visitor=<id>`; never log an email address, password or token. Cross-cutting ones live in `config/initializers/security_event_logging.rb`; `lib/boot_report.rb` writes the `Boot:` line (commit, hosts, OAuth configuration) at server start.
- `docker-compose.yml` + `docker-compose.dev.yml` — base + dev overrides; the dev server is published on host port 3001 (`3001:3000` in `docker-compose.dev.yml`); `RAILS_SERVER_PORT` is the port Puma listens on inside the container (3000)
- `.rubocop.yml` — targets Ruby 4.0; the rubocop-rails, rubocop-rspec, rubocop-capybara and rubocop-factory_bot plugins are enabled

### Testing Stack

RSpec with Capybara (feature tests), FactoryBot (`spec/factories/`), Shoulda Matchers, and SimpleCov. Test files mirror `app/` under `spec/`.

**Keeping `./go test` and `./go smoke` in sync:**

- Smoke tests (`spec/smoke/`) are tagged `:smoke` and excluded from the regular suite via `config.filter_run_excluding :smoke` in `spec/spec_helper.rb`. The `./go smoke` command re-includes them with `--tag smoke`. Never remove that exclusion — smoke tests make live HTTP calls and will fail with `ECONNREFUSED` when run without a live server.
- When app behavior changes (new HTTP status codes, response bodies, URL paths, UI text), update **both** the unit/feature tests and the smoke tests in the same commit. The two suites test the same contracts from different angles.
- The smoke spec `spec/smoke/visitor_api_flow_spec.rb` documents the expected API contract (status codes, response shapes, break-even math). Keep it in sync with `spec/requests/api/v1/` request specs and `spec/support/api_schemas/*.json` JSON schemas.

## Dockerfile Changes

Test plans for Dockerfile changes do not need to include steps for building the image or running the test suite — CI handles both automatically on every PR. The test plan only needs to cover anything CI cannot verify, such as confirming the app starts correctly locally or checking that a new system dependency is available inside the container.

CI (`.circleci/config.yml`) runs three parallel jobs on machine executors: `verify` (CI image, RuboCop, RSpec, on arm64) and `build_prod_arm64` / `build_prod_amd64`, which each build the production image natively on a runner of that architecture. Every branch therefore proves that `Dockerfile.production` builds on both architectures; `./go build prod --multi-platform` reproduces that locally (slow: the non-native half is emulated under QEMU, which is why CI does not do it). On `main` each `build_prod` job pushes its image untagged with `./go push prod --digest-only`, and `publish_manifest` then joins the two into one multi-arch manifest (`linux/amd64` + `linux/arm64`) with `./go push prod --manifest`. Only that last job creates the `:latest` and semver tags, and it waits for all three jobs.

## GitHub Workflow

Use the `gh` CLI (not `hub`) for all GitHub operations such as opening pull requests. `hub`'s token gets `Forbidden (HTTP 403): Resource not accessible by personal access token` when opening PRs on this repo.

```bash
gh pr create --draft --title "Title" --body "Body"
```

## Knowledge graph

`graphify-out/` holds a [graphify](https://pypi.org/project/graphifyy/) knowledge graph of `main`: `graph.json`, a plain-language `GRAPH_REPORT.md` and `graph.html`. It is gitignored, a local artifact like `tmp/`: a fresh clone, a CI build and a cloud session have none and build none.

**Graph first for questions about structure.** When `graphify-out/graph.json` exists, a question about structure, callers, dependencies, "what breaks if this changes" or "where is X" goes to the graph first, and files are read to confirm, not to search:

```bash
graphify query "how does a visitor's scenario reach the chart?" --budget 2000
graphify path "SolutionPair" "AutomationScenarioForGraphSerializer"
graphify explain "Visitable"
graphify affected app/services/solution_pair.rb
```

If `graphify` is not on the `PATH`, the interpreter recorded in `graphify-out/.graphify_python` has it: `"$(cat graphify-out/.graphify_python)" -m graphify query ...`. Finding a name or a string you already know stays with grep, which is as fast and exact. The graph is a snapshot (`main` as of its last refresh; in a worktree, the branch as of its last `./go graphify-update`), so read a file before you edit it.

**Keeping it current.** The graph has two layers with two costs:

- The **code layer** is parsed by AST: no LLM, seconds. `./go graphify-update` refreshes it to `HEAD` and is safe to run unattended. It exits 0 with a note and does nothing when there is no graph yet, when the main checkout is not on `main`, and in CI or a cloud session. `./go graphify-status` says how far behind the graph is (exit 0 current, 3 behind, 1 no graph). On the laptop the repo-standards git-sync agent fast-forwards `main` at 07:00 and 23:00 and then runs `[git-sync] post_sync = "./go graphify-update"` from `.repo-standards.toml`, so a merged PR reaches the graph without a step from its author. After moving `main` by hand (`git pull`), run `./go graphify-update`.
- The **document layer** (Markdown, images) is extracted by an LLM pass, `/graphify --update` in a session, and costs tokens. It runs when a person asks for it, in the main checkout on `main`, never from a hook. `./go graphify-status` lists the documents that wait for it. The first build of the graph is `/graphify .`, under the same rule.

**The graph is `main`'s, and never part of a pull request.** It is not rebuilt on a feature branch in the main checkout and `graphify-out/` is never committed. A git worktree gets a private copy instead: `./go graphify-seed` copies the main checkout's graph, shares its extraction caches by symlink, and refreshes the code layer to the worktree's `HEAD`; `./go graphify-update` then refreshes that copy after edits, commits, or a merge of `origin/main`. Nothing is copied back: the copy goes away with the worktree, and `main`'s graph gets the merged work from `main`. `graphify hook install` is not used here, because it makes the graph follow whatever branch is checked out.

`.graphifyignore` (gitignore syntax) keeps generated, vendored and captured files out of the graph; add to it when a new directory of that kind appears. The commands live in `scripts/graphify.rb` and `scripts/graphify_status.rb`; `scripts/graphify/graphify_seed.py` is the repo-standards template (`templates/graphify/graphify_seed.py`), copied unchanged: take upstream changes by copying it again rather than editing it here.

## Repo standards

This repo follows https://github.com/stevenuray/repo-standards; `.repo-standards.toml` lists the rules it does not adopt, with reasons. Audit with `python3 ~/git/repo-standards/scripts/audit_repo.py .` (needs Python 3.11+).
