# ./go logs: follow the dev container's logs.
require './scripts/utils/compose_files'
require './scripts/utils/runner'

class Logs
  def initialize(runner: Runner.new)
    @runner = runner
  end

  # The dev service is defined in the dev compose file, so its flags are
  # needed here as everywhere else. Not checked: Ctrl-C is how it ends.
  def logs
    @runner.run("docker compose #{ComposeFiles.flags('dev')} logs --follow dev")
  end
end
