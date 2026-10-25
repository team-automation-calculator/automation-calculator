---
name: deploy-image
description: Promote an app image through staging to production with a smoke-test baseline and retest at each step. Use when asked to deploy, roll out, baseline, or watch a deploy of a 0.9.6-<build> image, or to verify staging or production after a deploy.
---

# Deploy an app image: baseline, deploy, retest, then production

The app has no release process beyond this: a green `main` build pushes an
image, a `core-iac` PR pins that image, Terraform Cloud rolls it out. This
skill is the verification wrapped around those steps so that every rollout
has a before/after comparison on both environments.

Promotion order is always **staging first, then production**, and production
is only started after staging's retest matches its baseline.

## Facts you need

- **Image tag ↔ commit.** The tag is `0.9.6-<CircleCI build number>` (the
  semver comes from CircleCI project env vars, not a repo file). Map a commit
  to its build with the GitHub commit status; the `target_url` ends in the
  build number:

  ```bash
  gh api repos/team-automation-calculator/automation-calculator/commits/<sha>/status \
    --jq '.state, (.statuses[] | .target_url)'
  ```

  Confirm the tag exists before anything else:

  ```bash
  curl -s "https://hub.docker.com/v2/repositories/automationcalculationsci/automation-calculator/tags?page_size=5&ordering=last_updated" \
    | python3 -I -c 'import json,sys; [print(t["name"], t["last_updated"]) for t in json.load(sys.stdin)["results"]]'
  ```

  Never deploy `latest`. Only `main` builds push since #222, but `latest` is
  still just "most recent", not "approved".

- **What is deployed where.** `GET /health` on each environment returns
  `short_commit_hash`. That is the only signal you need to detect a rollout.

  | Environment | URL |
  |---|---|
  | staging | `https://staging.automation-calculations.io` |
  | production | `https://automation-calculations.io` |

- **How a deploy happens.** `core-iac/scripts/bump_app_docker_image_version_branch.sh <tag> <short_sha>`
  (or `core-iac/scripts/watch_app_docker_image_versions.py`, which runs it
  when a new tag appears on Docker Hub) opens one PR that bumps `app_version`
  and `short_commit_hash` in the development, staging **and** production
  `terraform.tfvars` plus `helm/automation-calculator/values.yaml`. Merging
  it triggers Terraform Cloud runs:
  - **staging auto-applies**, usually 3–5 minutes after merge;
  - **production stops at "apply pending"** and needs a confirm in the
    Terraform Cloud UI. That confirm is the staging→production gate. The
    user does it; this skill never does.

  Run states show on the `core-iac` merge commit:

  ```bash
  gh api repos/team-automation-calculator/core-iac/commits/main/status \
    --jq '.statuses[] | select(.context | startswith("Terraform Cloud")) | "\(.context) \(.state) \(.updated_at) \(.description)"'
  ```

  Caveat: that status reflects the push-triggered run only. A manual run
  started in the Terraform Cloud UI does not update it, so a "plan: N to
  add" there can be stale. Trust `/health`, not the status, for what is live.

## Checks

Run every check from this repo's checkout. The dev image must be current
(`./go build` after Gemfile changes); the smoke specs load only
`spec_helper`, not Rails, so no database is needed.

**Smoke suite** (the contract: 49 examples, 0 failures, 2 pending on a
deployed target; the 2 pending are the dev-only OAuth cases and are
expected):

```bash
./go smoke staging      # or: ./go smoke prod
```

If another checkout's `db` container is up and compose refuses to start,
either copy `docker-compose.local.example.yml` to `docker-compose.local.yml`
(see CLAUDE.md) or run the suite without compose:

```bash
docker run --rm -v "$(pwd):/usr/src/app" -w /usr/src/app \
  -e SMOKE_TARGET_URL=https://staging.automation-calculations.io \
  -e RAILS_ENV=test -e USER="$USER" --user "$USER" \
  automation-calculator-dev:latest rspec spec/smoke/ --tag smoke
```

**Asset check.** Scrape the `/assets/` URLs from `/` and fetch each. Every
asset must return 200 with the right content type and a plausible size.
Digests change whenever the bundle changes; sizes within a few percent are
normal. An empty or sharply smaller CSS or JS file, or a 404, is a
regression.

```bash
H=https://staging.automation-calculations.io
curl -s "$H/" | grep -oE '(href|src)="[^"]*/assets/[^"]+"' | sed -E 's/^(href|src)="//; s/"$//' | sort -u \
  | while read -r u; do printf '%s ' "$u"; curl -s -o /dev/null -w 'HTTP %{http_code} %{size_download}B %{content_type}\n' "$H$u"; done
```

**Health and host authorization.** `/health` is 200 with `"database":"ok"`;
`/` is 200; `/` with `X-Forwarded-Host: attacker.example` is 403;
`/users/sign_in` is 200.

**Change-specific checks.** Add whatever the image's diff calls for, and
say explicitly what the suite cannot cover:

| Image changes… | Also verify |
|---|---|
| Devise, OmniAuth, JWT, session | The suite only checks the outbound OAuth redirect. Ask the user to do a full round-trip Google **and** GitHub sign-in on the environment, and record that they did. |
| Asset pipeline (sass, terser, sprockets, precompile) | Asset check on every asset, plus the font or image URLs referenced from inside the CSS. |
| Puma, pg, Rails major/minor | Watch `/health` through the whole rollout for any non-200 or unreachable response, not just the final flip. |
| Host authorization, ingress, ALB controller | Forged `X-Forwarded-Host` on `/` is 403 and on `/health` is 200. |

## Procedure

1. **Identify the candidate.** Main head sha, its CircleCI build number, the
   tag present on Docker Hub, and the PR(s) it contains. If CI is still
   running, watch the commit status for a terminal state before going on.
2. **Baseline staging.** Record `/health`'s hash, run the smoke suite and the
   asset check, note the numbers. Do this *before* the bump PR merges so the
   baseline is on the old image.
3. **Deploy to staging.** The bump PR is opened by the `core-iac` scripts and
   merged by the user (merge it yourself only if explicitly asked). Then
   watch staging's `/health` until `short_commit_hash` equals the candidate
   sha, polling every 20–30 s, and report any unhealthy or unreachable
   responses seen along the way. A background monitor is the right tool; do
   not sleep-poll in the foreground.
4. **Retest staging.** Same checks as the baseline, plus the change-specific
   ones. Compare against the baseline. Any new failure, pending-count change,
   missing asset, or health miss stops the promotion here: report it, do not
   move to production.
5. **Baseline production.** Only after staging matches. Same checks, on the
   production URL, while production is still on the previous image.
6. **Deploy to production.** Tell the user the Terraform Cloud production
   run is at "apply pending" and wait for them to confirm it. Watch
   production's `/health` the same way as staging.
7. **Retest production.** Same checks. Production assets should be
   byte-identical (same digests and sizes) to staging's for the same image.
8. **Record.** State the before/after result for each environment, the time
   each hash flipped, what the suite could not verify, and what the user
   verified by hand. The new image is now the baseline for attributing the
   next regression.

## Report shape

One table per environment, before and after, then bullets for anything
the user has to act on:

| Staging | Result |
|---|---|
| Before (`<old sha>`, image `-<old>`) | 49 examples, 0 failures, 2 pending |
| After (`<new sha>`, image `-<new>`) | 49 examples, 0 failures, 2 pending |

## Rules

- Never confirm a Terraform Cloud apply, never merge a bump PR, and never
  push to `main` unless the user asks for that specific action.
- Never report a deploy as good because nothing failed loudly. A rollout is
  verified when the retest ran against the new hash and matched the
  baseline, and the report says so with the numbers.
- Never skip the production baseline because "it is the same image staging
  had". The baseline is what makes a production regression attributable.
- When the suite's expectations change with the app (new status codes,
  pages, response shapes), update `spec/smoke/` in the same PR as the app
  change; CLAUDE.md explains how the smoke and unit suites stay in sync.
