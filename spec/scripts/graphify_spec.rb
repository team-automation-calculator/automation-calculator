require_relative 'support/script_helpers'

RSpec.describe Graphify do
  include_context 'with graphify on a recording runner'

  describe '#ephemeral_reason' do
    it 'is nil on a persistent machine' do
      expect(described_class.new(env: {}).ephemeral_reason).to be_nil
    end

    it 'names the variable that marks a throwaway environment' do
      %w[CI GITHUB_ACTIONS CLAUDE_CODE_REMOTE].each do |name|
        expect(described_class.new(env: { name => 'true' }).ephemeral_reason).to start_with("#{name} is set")
      end
    end

    it 'reads empty, 0 and false as unset' do
      ['', ' ', '0', 'false', 'False'].each do |value|
        expect(described_class.new(env: { 'CI' => value }).ephemeral_reason).to be_nil
      end
    end
  end

  describe '#update' do
    it 'skips in a throwaway environment' do
      env['CI'] = 'true'
      expect { graphify.update([]) }.to output(/skipping: CI is set/).to_stdout
    end

    it 'skips in a worktree with no graph' do
      graph_exists(false)
      expect { graphify.update([]) }.to output(%r{skipping: no graphify-out/graph.json in this worktree}).to_stdout
    end

    it 'fails when graphify is not installed' do
      graph_exists(true)
      expect { graphify.update([]) }.to raise_error(CommandFailure, /not installed/)
    end

    context 'with a graph and graphify on the PATH' do
      let(:update) { ['/nowhere/graphify', 'update', '.'] }

      before do
        graph_exists(true)
        allow(File).to receive(:file?).with('/nowhere/graphify').and_return(true)
        allow(File).to receive(:executable?).and_call_original
        allow(File).to receive(:executable?).with('/nowhere/graphify').and_return(true)
      end

      it 'refreshes the code layer and records HEAD', :aggregate_failures do
        runner.captures[update] = ["done\n", '', RecordingRunner::OK]
        expect { graphify.update([]) }.to output(/done\ngraphify: code layer refreshed to 0123456/).to_stdout
        expect(File).to have_received(:write).with(Graphify::SYNCED_FILE, "0123456789abcdef\n")
      end

      it 'rebuilds with --force when graphify refuses a smaller graph', :aggregate_failures do
        runner.captures[update] = ['', 'Refusing to overwrite', RecordingRunner::FAILED]
        runner.captures[update + ['--force']] = ['', '', RecordingRunner::OK]
        expect { graphify.update([]) }.to output(/rebuilding with --force/).to_stdout
        expect(runner.calls.last(2).first.env).to eq('GRAPHIFY_NO_TIPS' => '1')
      end

      it 'fails when the refresh fails' do
        runner.captures[update] = ['', 'boom', RecordingRunner::FAILED]
        expect { graphify.update([]) }.to raise_error(CommandFailure, "graphify: update failed\nboom")
      end
    end
  end

  describe '#seed' do
    it 'runs the seed script with the flags given' do
      graphify.seed(['--quiet'])
      expect(runner.commands).to eq(['python3 scripts/graphify/graphify_seed.py --quiet'])
    end
  end
end
