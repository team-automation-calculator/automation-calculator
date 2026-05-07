# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

All commands run via the `./go` script (a Ruby dispatcher into `scripts/`):

```bash
./go init              # First-time setup: build images and run db setup
./go start             # Start dev server at http://localhost:3001/
./go test              # Run full RSpec suite in Docker
./go lint              # Run RuboCop in Docker
./go shell             # Open a shell in the dev container
./go stop              # Stop containers
./go clean             # Remove all containers, images, volumes
./go build             # Rebuild Docker images (required after Gemfile changes)
./go db dev            # Connect to PostgreSQL with psql
./go logs              # Tail container logs
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

**Troubleshooting:**
- After updating the Gemfile, run `./go build` before `./go test` or `./go start`.
- If `./go start` exits with "A server is already running", run `./go shell` then `rm /usr/src/app/tmp/pids/server.pid`.

## Architecture

### Two Parallel Interfaces

The app exposes the same domain through two completely separate stacks:

1. **HTML web interface** — Haml views, Bootstrap 4, Rails form submissions, Devise session authentication. Entry point: `AutomationScenariosController` (`app/controllers/automation_scenarios_controller.rb`).
2. **JSON API** — `app/controllers/api/v1/`, JWT token authentication via `HTTP_ACCESS_TOKEN` header, ActiveModel Serializers for responses. Routes are version-gated by a `Constraint` class.

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

`JwtTokenService` (`app/services/jwt_token_service.rb`) encodes/decodes tokens using `Rails.application.secrets.secret_key_base`. The payload contains either `user_id` or `visitor_id`. Token expiry is controlled by `Settings.api_session_duration` (minutes, from `config/settings.yml`).

### Key Configuration

- `config/settings.yml` — app-level config accessed via `Settings.*` (the `config` gem)
- `docker-compose.yml` + `docker-compose.dev.yml` — base + dev overrides; `RAILS_SERVER_PORT` defaults to 3001
- `.rubocop.yml` — targets Ruby 2.4; RuboCop-RSpec cops enabled

### Testing Stack

RSpec with Capybara (feature tests), FactoryBot (`spec/factories/`), Shoulda Matchers, and SimpleCov. Test files mirror `app/` under `spec/`.
