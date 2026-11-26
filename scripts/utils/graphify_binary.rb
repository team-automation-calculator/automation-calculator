# Where graphify is installed: the command line that runs it, or nil.
class GraphifyBinary
  def initialize(python_file:, env: ENV)
    @python_file = python_file
    @env = env
  end

  # launchd's PATH (git-sync) has no pyenv or pipx shim, so the interpreter
  # the skill recorded comes before the PATH.
  def command
    recorded_python || on_path
  end

  private

  def recorded_python
    return unless File.file?(@python_file)

    python = File.read(@python_file).strip
    [python, '-m', 'graphify'] if executable?(python)
  end

  def on_path
    binary = @env.fetch('PATH', '').split(File::PATH_SEPARATOR)
                 .map { |dir| File.join(dir, 'graphify') }
                 .find { |path| executable?(path) }
    binary && [binary]
  end

  def executable?(path)
    File.file?(path) && File.executable?(path)
  end
end
