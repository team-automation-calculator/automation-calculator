#!/usr/bin/env python3
"""Read and tick the Markdown checklists in the bodies of the PRs an image contains.

Every upgrade PR ends with a "Test plan" whose unchecked items are the checks
that could only be done once the image is live ("Staging: `./go smoke staging`
49/0/2 before and after", "GitHub and Google sign-in round trips", ...). The
deploy-image skill reads those items before the rollout, runs the ones it can,
and ticks them afterwards with a note saying what was observed and where, so
the PR records its own verification.

Run:  python3 -I .claude/skills/deploy-image/scripts/pr_checklist.py prs <old_sha> <new_sha>
      python3 -I .claude/skills/deploy-image/scripts/pr_checklist.py list 238 241
      python3 -I .claude/skills/deploy-image/scripts/pr_checklist.py list 238 --open
      python3 -I .claude/skills/deploy-image/scripts/pr_checklist.py check 238 \
          --match 'smoke staging' --note 'staging 49/0/2 before (-950) and after (-951), 2026-10-26' --dry-run
      python3 -I .claude/skills/deploy-image/scripts/pr_checklist.py note 238 \
          --match 'puma RSS' --note 'not checked: no kubeconfig context for staging'

`check` flips exactly one unchecked `- [ ]` item to `- [x]` and appends the
note; `note` appends without ticking (for a check that was skipped or failed).
Both refuse to act when the match text hits zero or more than one item, change
nothing else in the body, and print the before/after lines. Use `--dry-run`
first. Nothing here ever unticks an item or rewrites other text.
"""
import argparse
import json
import re
import subprocess
import sys
import tempfile

REPO = "team-automation-calculator/automation-calculator"
ITEM = re.compile(r"^(?P<indent>\s*)(?P<bullet>[-*])\s+\[(?P<state>[ xX])\]\s+(?P<text>.*)$")


def gh(*args):
    result = subprocess.run(["gh", *args], check=True, capture_output=True, text=True)
    return result.stdout


def body_of(number):
    return json.loads(gh("pr", "view", str(number), "--repo", REPO, "--json", "body,title,state,url"))


def items(body):
    found = []
    for index, line in enumerate(body.splitlines()):
        match = ITEM.match(line)
        if match:
            found.append((index, match.group("state") != " ", match.group("text")))
    return found


def cmd_prs(args):
    shas = subprocess.run(
        ["git", "rev-list", f"{args.old}..{args.new}"], check=True, capture_output=True, text=True
    ).stdout.split()
    merged = json.loads(
        gh("pr", "list", "--repo", REPO, "--state", "merged", "--base", "main",
           "--limit", "100", "--json", "number,title,mergeCommit,mergedAt")
    )
    rows = [pr for pr in merged if pr["mergeCommit"] and pr["mergeCommit"]["oid"] in shas]
    rows.sort(key=lambda pr: pr["mergedAt"])
    if not rows:
        print(f"no merged PR has its merge commit in {args.old[:7]}..{args.new[:7]}", file=sys.stderr)
        return 1
    for pr in rows:
        print(f"#{pr['number']} {pr['mergeCommit']['oid'][:7]} {pr['mergedAt']} {pr['title']}")
    return 0


def cmd_list(args):
    for number in args.pr:
        pr = body_of(number)
        print(f"#{number} [{pr['state']}] {pr['title']}")
        for _, done, text in items(pr["body"]):
            if args.open and done:
                continue
            print(f"  [{'x' if done else ' '}] {text}")
        print()
    return 0


def edit(args, tick):
    pr = body_of(args.pr)
    body = pr["body"]
    lines = body.splitlines(keepends=True)
    hits = [(i, done, text) for i, done, text in items(body) if args.match in text and not done]
    if len(hits) != 1:
        state = "no unchecked item" if not hits else f"{len(hits)} unchecked items"
        print(f"#{args.pr}: {state} match {args.match!r}; refusing to edit", file=sys.stderr)
        for _, _, text in hits:
            print(f"  [ ] {text}", file=sys.stderr)
        return 1
    index = hits[0][0]
    old = lines[index]
    newline = old[len(old.rstrip("\r\n")):]
    stripped = old.rstrip("\r\n")
    if tick:
        stripped = re.sub(r"\[ \]", "[x]", stripped, count=1)
    if args.note:
        stripped = f"{stripped} — {args.note}"
    lines[index] = stripped + newline
    print(f"#{args.pr} {pr['url']}\n- {old.rstrip()}\n+ {stripped}")
    if args.dry_run:
        print("(dry run, PR not edited)")
        return 0
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as handle:
        handle.write("".join(lines))
        path = handle.name
    gh("pr", "edit", str(args.pr), "--repo", REPO, "--body-file", path)
    print("edited")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    prs = sub.add_parser("prs", help="merged PRs whose merge commit lies in old..new")
    prs.add_argument("old")
    prs.add_argument("new")
    prs.set_defaults(func=cmd_prs)

    lst = sub.add_parser("list", help="checklist items of one or more PRs")
    lst.add_argument("pr", nargs="+", type=int)
    lst.add_argument("--open", action="store_true", help="unchecked items only")
    lst.set_defaults(func=cmd_list)

    for name, tick, help_text in (
        ("check", True, "tick one unchecked item and append a note"),
        ("note", False, "append a note to one unchecked item without ticking it"),
    ):
        cmd = sub.add_parser(name, help=help_text)
        cmd.add_argument("pr", type=int)
        cmd.add_argument("--match", required=True, help="text that appears in exactly one unchecked item")
        cmd.add_argument("--note", required=not tick, help="what was observed, where and when")
        cmd.add_argument("--dry-run", action="store_true")
        cmd.set_defaults(func=lambda args, tick=tick: edit(args, tick))

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
