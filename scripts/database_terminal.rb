# ./go db [dev]: psql on a container database.
require './scripts/utils/compose_files'
require './scripts/utils/runner'
require './scripts/utils/subcommands'

class DatabaseTerminal
  DATABASES = { dev: :connect_dev_db }.freeze

  def initialize(runner: Runner.new)
    @runner = runner
  end

  def connect(cmds)
    table = DATABASES.transform_values { |name| method(name) }
    Subcommands.dispatch(cmds, table, default: 'dev', help: 'db')
  end

  private

  def connect_dev_db
    @runner.replace("docker compose #{ComposeFiles.flags('dev')} run db_client")
  end
end
