# version_dates

Machine-readable record of what this app runs on, when each piece goes end-of-life,
and the phased plan to get to current versions.

| File | What it holds |
| --- | --- |
| `ruby.json`, `rails.json`, `linux.json`, `node.json`, `postgresql.json`, `key_gems.json` | The versions locked on `main` right now, with release and EOL dates. Refresh the one you change in any upgrade PR. |
| `latest_versions.json` | Latest published versions from rubygems.org, Docker Hub and NodeSource. Generated — do not hand-edit. |
| `upgrade_path.json` | The phased plan. Each phase is one PR. `depends_on` says what must be on `main` first; `parallel_tracks` groups the phases that can run side by side. |
| `phase_N_tracking.json` | What actually moved when phase N shipped, including anything held back and why. Written when the phase PR opens (`status: in_progress`), finalized when it merges (`status: completed`, plus `pr`, `merged`, `image`, `deployed`). |
| `fetch_latest_versions.py` | Regenerates `latest_versions.json`. |
| `gem_lines.py` | Prints the newest release of every minor line of a gem (date, Ruby requirement). For phases that target an intermediate line, e.g. Rails 7.1 while 8.1 is current. |

Refresh the snapshot before starting a phase:

```bash
python3 -I version_dates/fetch_latest_versions.py
python3 -I version_dates/gem_lines.py rails rspec-rails --min 7.1   # when the target is not the newest line
```

Both need only `curl` and Python 3.9+, no API keys. Docker Hub rate-limits unauthenticated
paging, so each repo is queried with a `name=` filter to keep it to a few pages.
