require './scripts/utils/command_failure'

# The first step of ./go lint: fails when git tracks an environment file
# (.env, .env.production, config/.env, ...). Those hold secrets, which come
# from the environment through AppConfig instead (twelve-factor rule,
# AGENTS.md). .gitignore keeps them out, but `git add -f` gets past it.
# .env.example, with placeholder values, may be tracked.
class TrackedEnvFiles
  ENV_FILE = /\A\.env(\.|\z)/.freeze
  ALLOWED = %w[.env.example].freeze

  def initialize(runner:)
    @runner = runner
  end

  # Raises CommandFailure naming every tracked environment file.
  def check
    found = offending_files
    return if found.empty?

    raise CommandFailure, "Environment files are tracked by git: #{found.join(', ')}\n" \
                          'Untrack each with `git rm --cached FILE` and rotate every secret it held: ' \
                          'they stay in git history.'
  end

  private

  def offending_files
    @runner.output('git ls-files -z').split("\0").select do |path|
      name = File.basename(path)
      name.match?(ENV_FILE) && !ALLOWED.include?(name)
    end
  end
end
