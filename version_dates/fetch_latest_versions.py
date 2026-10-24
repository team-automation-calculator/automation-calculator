#!/usr/bin/env python3
"""Snapshot the latest published version of every dependency this repo pins.

Queries rubygems.org, Docker Hub and NodeSource (no auth needed) and writes
version_dates/latest_versions.json so upgrade_path.json can be planned
against today's reality rather than memory.

Run:  python3 -I version_dates/fetch_latest_versions.py
"""
import json
import re
import subprocess
import sys
import urllib.request
from datetime import date
from pathlib import Path

GEMS = [
    "rails", "puma", "pg", "devise", "omniauth", "omniauth-google-oauth2",
    "omniauth-github", "omniauth-rails_csrf_protection", "jwt", "bootstrap",
    "haml", "haml-rails", "sass-rails", "sassc-rails", "sassc", "dartsass-rails",
    "dartsass-sprockets", "sassc-embedded", "sass-embedded",
    "sprockets", "sprockets-rails", "propshaft", "turbolinks", "turbo-rails",
    "coffee-rails", "uglifier", "terser", "jquery-rails", "config",
    "active_model_serializers", "rspec-rails", "capybara", "selenium-webdriver",
    "rubocop", "rubocop-rails", "rubocop-rspec", "rubocop-capybara",
    "rubocop-factory_bot", "nokogiri", "factory_bot_rails", "faker",
    "shoulda-matchers", "simplecov", "database_cleaner",
    "database_cleaner-active_record", "json_matchers", "listen", "web-console",
    "guard", "guard-rspec", "guard-rubocop", "annotate", "annotaterb",
    "letter_opener", "jbuilder", "bundler", "importmap-rails", "execjs",
    "byebug", "pry", "rspec-its", "rake", "rack", "zeitwerk", "concurrent-ruby",
]

# repo -> (Docker Hub `name=` substring filter, regex applied to the result)
DOCKER_TAG_FILTERS = {
    "library/ruby": ("slim-trixie", r"^\d+\.\d+\.\d+-slim-trixie$"),
    "library/postgres": ("-alpine", r"^\d+(beta\d+|rc\d+)?-alpine$"),
    "cimg/ruby": ("-node", r"^\d+\.\d+-node$"),
}

NODE_CHANNELS = [20, 22, 24, 26]


HEADERS = {"User-Agent": "automation-calculator-version-check/1.0", "Accept": "application/json"}


def get_json(url):
    # Docker Hub answers urllib with 403 but curl with 200, so shell out to curl.
    result = subprocess.run(
        ["curl", "-sS", "--fail", "--max-time", "30", "-A", HEADERS["User-Agent"],
         "-H", "Accept: application/json", url],
        check=True, capture_output=True, text=True,
    )
    return json.loads(result.stdout)


def gem_latest(name):
    try:
        latest = get_json(f"https://rubygems.org/api/v1/versions/{name}/latest.json")
    except Exception as exc:  # noqa: BLE001 - report and keep going
        return {"error": str(exc)}
    version = latest.get("version")
    if version in (None, "unknown"):
        return {"error": "not found"}
    detail = get_json(f"https://rubygems.org/api/v2/rubygems/{name}/versions/{version}.json")
    return {
        "version": version,
        "released": detail.get("created_at", "")[:10],
        "ruby_version": detail.get("ruby_version"),
    }


def docker_tags(repo, name_filter, pattern):
    tags = set()
    url = f"https://hub.docker.com/v2/repositories/{repo}/tags?page_size=100&name={name_filter}"
    for _ in range(40):  # cap paging
        try:
            data = get_json(url)
        except Exception as exc:  # noqa: BLE001
            return {"error": str(exc), "partial": sorted(tags)}
        tags.update(t["name"] for t in data["results"] if re.match(pattern, t["name"]))
        url = data.get("next")
        if not url:
            break
    return sorted(tags, key=lambda t: [int(x) if x.isdigit() else x for x in re.split(r"(\d+)", t)])


def node_channels():
    out = {}
    for major in NODE_CHANNELS:
        req = urllib.request.Request(
            f"https://deb.nodesource.com/setup_{major}.x", method="HEAD", headers=HEADERS
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                out[str(major)] = resp.status
        except Exception as exc:  # noqa: BLE001
            out[str(major)] = str(exc)
    return out


def main():
    snapshot = {
        "fetched_on": date.today().isoformat(),
        "gems": {name: gem_latest(name) for name in GEMS},
        "docker_tags": {
            repo: docker_tags(repo, name_filter, pat)
            for repo, (name_filter, pat) in DOCKER_TAG_FILTERS.items()
        },
        "nodesource_setup_channels_http_status": node_channels(),
    }
    out = Path(__file__).with_name("latest_versions.json")
    out.write_text(json.dumps(snapshot, indent=2) + "\n")
    print(f"wrote {out}", file=sys.stderr)
    for name, info in snapshot["gems"].items():
        print(f"{name:32} {info.get('version', info.get('error'))}  {info.get('released', '')}  ruby {info.get('ruby_version', '')}")


if __name__ == "__main__":
    main()
