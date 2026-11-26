# Loads the ./go command classes the way ./go does, and records the shell
# commands they would run instead of running them.
Dir[File.expand_path('../../../scripts/*.rb', __dir__)].each { |file| require file }

module ScriptHelpers
  SHELL_OWNERS = [
    DatabaseTerminal, DockerBuild, DockerHub, GetUID, GitShortSha, Graphify, Lifecycle,
    Logs, Shell, Verify
  ].freeze

  # The commands run while the block executes, in order, each one a string
  # with runs of spaces squeezed. `responses` answers captured commands
  # (backticks) by their exact text.
  def commands_run(responses: {})
    log = []
    SHELL_OWNERS.each do |owner|
      record_runs(owner, log)
      record_captures(owner, log, responses)
    end
    yield
    log
  end

  # ENV with these variables set; a nil value unsets the variable.
  def env_with(vars)
    stub_const('ENV', ENV.to_h.merge(vars).compact)
  end

  private

  def record_runs(owner, log)
    allow(owner).to receive(:system) do |*args, **_opts|
      log << squeeze(args)
      true
    end
    allow(owner).to receive(:exec) { |*args| log << squeeze(args) }
  end

  def record_captures(owner, log, responses)
    allow(owner).to receive(:`) do |cmd|
      responses.fetch(cmd) { (log << squeeze(cmd)) && '' }
    end
  end

  def squeeze(args)
    Array(args).reject { |arg| arg.is_a?(Hash) }.join(' ').squeeze(' ').strip
  end
end

RSpec.shared_context 'with ./go collaborators stubbed' do
  include ScriptHelpers

  let(:responses) { { 'id -u' => "501\n", 'git rev-parse --short HEAD 2>/dev/null' => "abc1234\n" } }

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('docker-compose.local.yml').and_return(false)
  end
end

# git answers from the `git` hash (argument list => output); anything else
# fails. No graph file, nothing on the PATH, a persistent machine.
RSpec.shared_context 'with graphify git stubbed' do
  include ScriptHelpers

  let(:success) { instance_double(Process::Status, success?: true) }
  let(:failure) { instance_double(Process::Status, success?: false) }
  let(:git) { { %w[rev-parse HEAD] => "0123456789abcdef\n" } }

  before do
    env_with('CI' => nil, 'GITHUB_ACTIONS' => nil, 'CLAUDE_CODE_REMOTE' => nil, 'PATH' => '/nowhere')
    allow(Open3).to receive(:capture2) { |_git, *args, **| [git.fetch(args, ''), git.key?(args) ? success : failure] }
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:write)
  end

  def graph_exists(exists)
    allow(File).to receive(:file?).with(Graphify::GRAPH).and_return(exists)
  end
end
