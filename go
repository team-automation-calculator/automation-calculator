#! /usr/bin/env ruby

# The single entry point for this repo's commands (`./go help` lists them).
# It runs on the host's own Ruby, which can be older than the app's:
# scripts/.rubocop.yml keeps scripts/ to that older syntax.

# macOS exposes USERNAME; Linux exposes USER.
# Normalize to USER for docker-compose.
ENV['USER'] ||= ENV['USERNAME']
ENV['UID'] ||= Process.uid.to_s

Dir['./scripts/*.rb'].each { |file| require file }

GoCommands.run(ARGV)
