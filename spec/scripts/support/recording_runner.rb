# Stands in for Runner (scripts/utils/runner.rb) in specs: records what would
# run instead of running it.
class RecordingRunner
  Call = Struct.new(:kind, :command, :env, :check)
  Status = Struct.new(:exitstatus) do
    def success?
      exitstatus.zero?
    end
  end
  OK = Status.new(0)
  FAILED = Status.new(1)

  attr_reader :calls, :captures

  # outputs: shell command => its stdout. results: command => what run
  # returns (true by default).
  def initialize(outputs: {}, results: {})
    @outputs = outputs
    @results = results
    @captures = {}
    @calls = []
  end

  def run(command, env: {}, check: false)
    record(:run, command, env: env, check: check)
    result = @results.fetch(squeeze(command), true)
    raise "#{squeeze(command)} failed" if check && !result

    result
  end

  def replace(command)
    record(:replace, command)
  end

  # An unanswered command is recorded and outputs nothing.
  def output(command)
    @outputs.fetch(command) do
      record(:output, command)
      ''
    end
  end

  # An unanswered argument list fails.
  def capture(*argv, env: {})
    record(:capture, argv, env: env)
    @captures.fetch(argv) { ['', '', FAILED] }
  end

  # Every shell command, in order, as a string with runs of spaces squeezed.
  def commands
    calls.reject { |call| call.kind == :capture }.map(&:command)
  end

  private

  def record(kind, command, env: {}, check: false)
    calls << Call.new(kind, squeeze(command), env, check)
  end

  def squeeze(command)
    Array(command).join(' ').squeeze(' ').strip
  end
end
