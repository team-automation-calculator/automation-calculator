# Loads the ./go command classes the way ./go does. Each spec hands them a
# RecordingRunner, so nothing reaches the shell.
Dir[File.expand_path('../../../scripts/*.rb', __dir__)].each { |file| require file }
require_relative 'recording_runner'

RSpec.shared_context 'with a recording runner' do
  let(:outputs) { { 'id -u' => "501\n", 'git rev-parse --short HEAD 2>/dev/null' => "abc1234\n" } }
  let(:runner) { RecordingRunner.new(outputs: outputs) }

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('docker-compose.local.yml').and_return(false)
  end
end

# git answers only what a spec gives git_answers; no graph file, nothing on
# the PATH, a persistent machine.
RSpec.shared_context 'with graphify on a recording runner' do
  let(:runner) { RecordingRunner.new }
  let(:env) { { 'PATH' => '/nowhere' } }
  let(:graphify) { Graphify.new(runner: runner, env: env) }

  before do
    git_answers(%w[rev-parse HEAD] => "0123456789abcdef\n")
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:write)
  end

  # git argument list => its output
  def git_answers(answers)
    answers.each { |args, out| runner.captures[['git', *args]] = [out, '', RecordingRunner::OK] }
  end

  def graph_exists(exists)
    allow(File).to receive(:file?).with(Graphify::GRAPH).and_return(exists)
  end
end
