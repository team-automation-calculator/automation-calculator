# ./go shell [dev|ci|production]: bash inside a container.
require './scripts/utils/compose_files'
require './scripts/utils/host'
require './scripts/utils/runner'
require './scripts/utils/subcommands'

class Shell
  CONTAINERS = { dev: :dev_shell, ci: :ci_shell, production: :production_shell }.freeze

  def initialize(runner: Runner.new, env: ENV, host: Host.new(runner))
    @runner = runner
    @env = env
    @host = host
  end

  def shell(cmds)
    table = CONTAINERS.transform_values { |name| method(name) }
    Subcommands.dispatch(cmds, table, default: 'dev', help: 'shell')
  end

  private

  def ci_shell
    @runner.replace("USER=#{@env.fetch('USER', 'circleci')} docker compose #{ComposeFiles.flags('ci')} " \
                    'run --entrypoint /bin/bash ci')
  end

  def dev_shell
    @runner.replace("UID=#{@host.uid} docker compose #{ComposeFiles.flags('dev')} run dev /bin/bash")
  end

  def production_shell
    @runner.replace("docker compose #{ComposeFiles.flags('production_http')} run production /bin/bash")
  end
end
