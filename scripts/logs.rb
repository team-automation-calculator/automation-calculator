# ./go logs: follow the dev container's logs.
require './scripts/utils/runner'

class Logs
  def initialize(runner: Runner.new)
    @runner = runner
  end

  def logs
    @runner.run('docker compose logs --follow dev')
  end
end
