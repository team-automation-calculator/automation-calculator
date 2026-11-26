require 'open3'

# The one place ./go commands reach the shell. Every command class takes a
# runner in its initializer, so specs pass a recorder instead
# (spec/scripts/support/recording_runner.rb). The Scripts/ShellBoundary cop
# keeps system, exec, backticks and Open3 out of every other file in scripts/.
class Runner
  # Runs command (a shell string, or an argument list run without a shell)
  # with env added to the environment. True when it exits 0; with check, a
  # failure raises instead.
  def run(command, env: {}, check: false)
    system(env, *Array(command), exception: check)
  end

  # Replaces this process with command: an interactive shell, psql, setup.
  def replace(command)
    exec(command)
  end

  # Standard output of a shell command.
  def output(command)
    `#{command}`
  end

  # [stdout, stderr, status] of an argument list, run without a shell.
  def capture(*argv, env: {})
    Open3.capture3(env, *argv)
  end
end
