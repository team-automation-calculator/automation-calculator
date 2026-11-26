require './scripts/utils/runner'

# Facts about the machine ./go runs on, read through the runner.
class Host
  def initialize(runner = Runner.new)
    @runner = runner
  end

  def uid
    @runner.output('id -u').strip
  end

  # The short HEAD commit, or 'unknown' outside a git checkout.
  def git_short_sha
    sha = @runner.output('git rev-parse --short HEAD 2>/dev/null').strip
    sha.empty? ? 'unknown' : sha
  end
end
