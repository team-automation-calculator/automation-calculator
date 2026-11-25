#!/usr/bin/env python3
"""Seed a git worktree's graphify graph from the main checkout's (rule graphify).

The graph in graphify-out/ is main's and gitignored, so a new worktree has none.
This gives the worktree a copy of its own to query and to refresh as the branch
changes; the copy is never merged back and goes away with the worktree folder.

    ./go graphify-seed [--force] [--no-update] [--quiet]

What is seeded, and why not the whole folder:

- graph.json, GRAPH_REPORT.md and the community labels are copied.
- cache/ast and cache/semantic are symlinks to the main checkout's. Entries are
  keyed by file content and repo-relative path and written by rename, so
  worktrees share them safely, and an extraction paid for once is not paid
  for again. cache/stat-index.json is keyed by absolute path and rewritten
  whole, so each worktree keeps its own.
- .graphify_root is written fresh as `.`, what `graphify update .` writes itself:
  the main checkout's may name the main checkout by absolute path, and
  `graphify update` with no path would then scan that tree from here.
- manifest.json is left out: it is keyed by the main checkout's absolute paths.

Then `graphify update .` (AST only, no LLM) brings the code layer to this
worktree's HEAD. Standard library only; exits 0 whenever there is nothing to do.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

LOG = logging.getLogger("graphify-seed")
OUT = "graphify-out"
GRAPH = "graph.json"
COPIED = (GRAPH, "GRAPH_REPORT.md", ".graphify_labels.json", ".graphify_python")
SHARED_CACHES = ("ast", "semantic")
# Environments thrown away when they end: a graph built there is wasted work.
EPHEMERAL_VARIABLES = ("CLAUDE_CODE_REMOTE", "GITHUB_ACTIONS", "CI")
COPY_ATTEMPTS = 5
COPY_RETRY_SECONDS = 1.0
UPDATE_TIMEOUT_SECONDS = 600


def ephemeral_reason(env: dict[str, str]) -> str | None:
    """Why this environment gets no graph, or None on a persistent machine."""
    for name in EPHEMERAL_VARIABLES:
        if env.get(name, "").strip().lower() not in ("", "0", "false"):
            return f"{name} is set"
    return None


def git_path(cwd: Path, *args: str) -> Path | None:
    result = subprocess.run(
        ["git", "-C", str(cwd), "rev-parse", "--path-format=absolute", *args],
        capture_output=True,
        text=True,
        check=False,
    )
    out = result.stdout.strip()
    return Path(out).resolve() if result.returncode == 0 and out else None


def checkouts(cwd: Path) -> tuple[Path, Path] | None:
    """(this checkout's root, the main checkout's root), or None outside git."""
    here = git_path(cwd, "--show-toplevel")
    common = git_path(cwd, "--git-common-dir")
    if here is None or common is None:
        return None
    return here, common.parent


def copy_graph(source: Path, target: Path) -> bool:
    """Copy graph.json so that a half-written source is never left in place:
    the copy lands under a temporary name and is kept only if it parses."""
    for attempt in range(COPY_ATTEMPTS):
        handle, name = tempfile.mkstemp(
            dir=target.parent, prefix="graph.", suffix=".tmp"
        )
        os.close(handle)
        temporary = Path(name)
        try:
            shutil.copyfile(source, temporary)
            json.loads(temporary.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            temporary.unlink(missing_ok=True)
            LOG.debug("copy %d of %s did not parse: %s", attempt + 1, source, exc)
            time.sleep(COPY_RETRY_SECONDS)
            continue
        os.replace(temporary, target)
        return True
    return False


def link_caches(main_out: Path, out: Path) -> list[str]:
    """Point this worktree's cache/ast and cache/semantic at the main checkout's."""
    linked = []
    (out / "cache").mkdir(parents=True, exist_ok=True)
    for kind in SHARED_CACHES:
        shared = main_out / "cache" / kind
        link = out / "cache" / kind
        if link.is_symlink() or link.exists():
            continue
        shared.mkdir(parents=True, exist_ok=True)
        link.symlink_to(shared, target_is_directory=True)
        linked.append(kind)
    return linked


def update_command(out: Path) -> list[str] | None:
    """`graphify update .` through the interpreter the skill recorded, which is
    found where a pyenv or pipx shim is not (launchd, a hook's PATH)."""
    recorded = out / ".graphify_python"
    if recorded.is_file():
        python = recorded.read_text(encoding="utf-8").strip()
        if python and Path(python).is_file():
            return [python, "-m", "graphify", "update", "."]
    binary = shutil.which("graphify")
    return [binary, "update", "."] if binary else None


def seed(here: Path, main: Path, force: bool) -> str | None:
    """Seed `here` from `main`. Returns why nothing was done, or None when seeded."""
    main_out, out = main / OUT, here / OUT
    if not (main_out / GRAPH).is_file():
        return (
            f"the main checkout has no {OUT}/{GRAPH} yet (build it there: /graphify .)"
        )
    if (out / GRAPH).is_file() and not force:
        return f"{OUT}/{GRAPH} is already here (--force seeds again)"
    out.mkdir(exist_ok=True)
    if not copy_graph(main_out / GRAPH, out / GRAPH):
        return f"{main_out / GRAPH} did not parse after {COPY_ATTEMPTS} copies"
    for name in COPIED:
        if name != GRAPH and (main_out / name).is_file():
            shutil.copyfile(main_out / name, out / name)
    link_caches(main_out, out)
    (out / ".graphify_root").write_text(".", encoding="utf-8")
    return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--force", action="store_true", help="seed again over a graph already here"
    )
    parser.add_argument(
        "--no-update", action="store_true", help="copy only, do not run graphify update"
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="say nothing when there is nothing to do (SessionStart hook)",
    )
    parser.add_argument("--cwd", type=Path, default=Path.cwd(), help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="graphify-seed: %(message)s")
    skip = LOG.debug if args.quiet else LOG.info

    reason = ephemeral_reason(dict(os.environ))
    if reason:
        skip("skipping: %s", reason)
        return 0
    found = checkouts(args.cwd)
    if found is None:
        skip("skipping: not a git checkout")
        return 0
    here, main_checkout = found
    if here == main_checkout:
        skip("skipping: this is the main checkout, which owns the graph")
        return 0
    reason = seed(here, main_checkout, args.force)
    if reason:
        skip("skipping: %s", reason)
        return 0
    LOG.info("seeded %s/ from %s", OUT, main_checkout / OUT)
    if args.no_update:
        return 0
    command = update_command(here / OUT)
    if command is None:
        LOG.warning(
            "graphify not found: the graph is main's as copied, not this branch's"
        )
        return 0
    try:
        result = subprocess.run(
            command,
            cwd=here,
            capture_output=True,
            text=True,
            check=False,
            timeout=UPDATE_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        LOG.error("graphify update timed out after %ds", UPDATE_TIMEOUT_SECONDS)
        return 1
    if result.returncode != 0:
        LOG.error(
            "graphify update failed:\n%s", (result.stderr or result.stdout).strip()
        )
        return 1
    LOG.info("code layer refreshed to this worktree's HEAD (no LLM)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
