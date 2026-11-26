require_relative 'support/script_helpers'

RSpec.describe Graphify do
  describe '.ephemeral_reason' do
    it 'is nil on a persistent machine' do
      expect(described_class.ephemeral_reason({})).to be_nil
    end

    it 'names the variable that marks a throwaway environment' do
      %w[CI GITHUB_ACTIONS CLAUDE_CODE_REMOTE].each do |name|
        expect(described_class.ephemeral_reason(name => 'true')).to start_with("#{name} is set")
      end
    end

    it 'reads empty, 0 and false as unset' do
      ['', ' ', '0', 'false', 'False'].each do |value|
        expect(described_class.ephemeral_reason('CI' => value)).to be_nil
      end
    end
  end

  describe '.update' do
    include_context 'with graphify git stubbed'

    it 'skips in a throwaway environment' do
      env_with('CI' => 'true')
      expect { described_class.update([]) }.to output(/skipping: CI is set/).to_stdout
    end

    it 'skips in a worktree with no graph' do
      graph_exists(false)
      expect { described_class.update([]) }
        .to output(%r{skipping: no graphify-out/graph.json in this worktree}).to_stdout
    end

    it 'aborts when graphify is not installed' do
      graph_exists(true)
      expect { described_class.update([]) }.to raise_error(SystemExit).and output(/not installed/).to_stderr
    end

    context 'with a graph and graphify on the PATH' do
      before do
        graph_exists(true)
        allow(File).to receive(:file?).with('/nowhere/graphify').and_return(true)
        allow(File).to receive(:executable?).and_call_original
        allow(File).to receive(:executable?).with('/nowhere/graphify').and_return(true)
      end

      it 'refreshes the code layer and records HEAD', :aggregate_failures do
        allow(Open3).to receive(:capture3).and_return(["done\n", '', success])
        expect { described_class.update([]) }.to output(/done\ngraphify: code layer refreshed to 0123456/).to_stdout
        expect(File).to have_received(:write).with(Graphify::SYNCED_FILE, "0123456789abcdef\n")
      end

      it 'rebuilds with --force when graphify refuses a smaller graph', :aggregate_failures do
        allow(Open3).to receive(:capture3).and_return(['', 'Refusing to overwrite', failure], ['', '', success])
        expect { described_class.update([]) }.to output(/rebuilding with --force/).to_stdout
        expect(Open3).to have_received(:capture3)
          .with(hash_including('GRAPHIFY_NO_TIPS' => '1'), '/nowhere/graphify', 'update', '.', '--force')
      end

      it 'aborts when the refresh fails' do
        allow(Open3).to receive(:capture3).and_return(['', 'boom', failure])
        expect { described_class.update([]) }.to raise_error(SystemExit).and output(/update failed\nboom/).to_stderr
      end
    end
  end

  describe '.seed' do
    include_context 'with graphify git stubbed'

    it 'runs the seed script with the flags given' do
      expect(commands_run { described_class.seed(['--quiet']) })
        .to eq(['python3 scripts/graphify/graphify_seed.py --quiet'])
    end
  end
end
