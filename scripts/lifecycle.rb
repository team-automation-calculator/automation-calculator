# ./go init, start, stop, restart, clean, rm and rmi: the containers' lifecycle.
require './scripts/docker_build'
require './scripts/environment_variables'
require './scripts/utils/clear_rails_pid'
require './scripts/utils/compose_files'
require './scripts/utils/host'
require './scripts/utils/runner'
require './scripts/utils/subcommands'

class Lifecycle
  START_TARGETS = {
    dev: :start_dev,
    production: :start_production,
    debug_production: :start_debug_production
  }.freeze

  def initialize(runner: Runner.new, env: ENV, host: Host.new(runner),
                 docker_build: DockerBuild.new(runner: runner))
    @runner = runner
    @env = env
    @host = host
    @docker_build = docker_build
  end

  def init(cmds)
    @docker_build.build(['base'])
    @docker_build.build(cmds)
    @runner.replace(%(UID=#{@host.uid} docker compose #{ComposeFiles.flags('dev')} run dev "/usr/src/app/bin/setup"))
  end

  def start(cmds = [])
    table = START_TARGETS.transform_values { |name| method(name) }
    Subcommands.dispatch(cmds, table, default: 'dev', help: 'start')
  end

  def stop
    @runner.run('docker compose down --remove-orphans')
  end

  def restart
    stop
    start
  end

  def clean
    @runner.run('docker compose down --remove-orphans --rmi all --volumes')
  end

  # Stop, then remove every container.
  def rm
    @runner.run('docker compose down')
    @runner.replace('docker ps -aq | xargs docker rm')
  end

  # Stop this checkout's containers and remove the images its compose project
  # built (the dev image); pulled images such as postgres and the database
  # volume stay.
  def rmi
    @runner.replace("docker compose #{ComposeFiles.flags('dev')} down --rmi local")
  end

  private

  def start_dev
    ClearRailsPid.clear_pid_file_if_it_exists
    @runner.run("UID=#{@host.uid} docker compose #{ComposeFiles.flags('dev')} up -d dev")
  end

  def start_production
    @runner.run("docker compose #{ComposeFiles.flags('production_http')} up -d")
  end

  # Production, locally, with mock secrets for whatever the shell lacks.
  def start_debug_production
    @runner.run("docker compose #{ComposeFiles.flags('production_http')} up -d production",
                env: EnvironmentVariables.missing_production_vars(@env))
  end
end
