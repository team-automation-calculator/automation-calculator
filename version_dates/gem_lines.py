#!/usr/bin/env python3
"""Print the newest release of every minor line of a gem, with date and Ruby requirement.

latest_versions.json only records the single newest release of each gem. When a
phase targets an intermediate line (Rails 7.1 while 8.1 is current, rspec-rails 7
while 8 is current) this answers "what is the newest 7.1.x and what Ruby does it
need" without leaving the terminal.

Run:  python3 -I version_dates/gem_lines.py rails rspec-rails haml
      python3 -I version_dates/gem_lines.py rails --min 7.1
"""
import argparse
import json
import subprocess
import sys

USER_AGENT = "automation-calculator-version-check/1.0"


def versions(name):
    # Docker Hub answers urllib with 403 but curl with 200 (see
    # fetch_latest_versions.py); rubygems is fine either way, keep one method.
    result = subprocess.run(
        ["curl", "-sS", "--fail", "--max-time", "30", "-A", USER_AGENT,
         "-H", "Accept: application/json",
         f"https://rubygems.org/api/v1/versions/{name}.json"],
        check=True, capture_output=True, text=True,
    )
    return json.loads(result.stdout)


def version_key(number):
    return [int(part) if part.isdigit() else part for part in number.split(".")]


def newest_per_line(releases, minimum):
    lines = {}
    for release in releases:
        if release.get("prerelease"):
            continue
        number = release["number"]
        parts = number.split(".")
        if len(parts) < 2 or not all(p.isdigit() for p in parts):
            continue
        line = f"{parts[0]}.{parts[1]}"
        if minimum and version_key(line) < version_key(minimum):
            continue
        current = lines.get(line)
        if current is None or version_key(number) > version_key(current["number"]):
            lines[line] = release
    return [lines[line] for line in sorted(lines, key=version_key)]


def main():
    parser = argparse.ArgumentParser(description=(__doc__ or "").split("\n", maxsplit=1)[0])
    parser.add_argument("gems", nargs="+")
    parser.add_argument("--min", default=None, help="lowest minor line to show, e.g. 7.1")
    args = parser.parse_args()

    for name in args.gems:
        try:
            releases = versions(name)
        except subprocess.CalledProcessError as exc:
            print(f"{name}: {exc.stderr.strip()}", file=sys.stderr)
            continue
        print(f"== {name}")
        for release in newest_per_line(releases, args.min):
            ruby = release.get("ruby_version") or "-"
            print(f"  {release['number']:<12} {release['created_at'][:10]}  ruby {ruby}")


if __name__ == "__main__":
    main()
