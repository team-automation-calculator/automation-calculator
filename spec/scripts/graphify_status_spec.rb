require_relative 'support/script_helpers'

RSpec.describe GraphifyStatus do
  describe '.document?' do
    it 'is true for files the LLM pass extracts' do
      %w[AGENTS.md docs/app-structure.SVG apiary.apib].each do |path|
        expect(described_class.document?(path)).to be(true)
      end
    end

    it 'is false for code, which the AST pass covers' do
      %w[app/models/solution.rb go app/assets/javascripts/a.coffee].each do |path|
        expect(described_class.document?(path)).to be(false)
      end
    end
  end

  describe '.pending_documents' do
    let(:manifest) do
      {
        'README.md' => { 'ast_hash' => 'a', 'semantic_hash' => '' },
        'AGENTS.md' => { 'ast_hash' => 'b', 'semantic_hash' => 'c' },
        'About.md' => { 'ast_hash' => 'd' },
        'app/models/solution.rb' => { 'ast_hash' => 'e', 'semantic_hash' => '' },
        'legacy.md' => 1_700_000_000.0
      }
    end

    it 'lists the documents with no semantic hash, sorted' do
      expect(described_class.pending_documents(manifest)).to eq(%w[About.md README.md])
    end
  end

  describe '.status' do
    include_context 'with graphify git stubbed'

    let(:verify_synced) { ['rev-parse', '--verify', '--quiet', '0123456789abcdef^{commit}'] }

    it 'says nothing in --brief mode in a throwaway environment' do
      env_with('CI' => '1')
      expect { described_class.status(['--brief']) }.not_to output.to_stdout
    end

    it 'exits 1 with no graph' do
      graph_exists(false)
      expect { described_class.status([]) }
        .to raise_error(an_object_having_attributes(status: 1)).and output(/no graphify-out/).to_stdout
    end

    context 'with a graph' do
      before do
        graph_exists(true)
        allow(File).to receive(:file?).with(Graphify::SYNCED_FILE).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(Graphify::SYNCED_FILE).and_return("0123456789abcdef\n")
        allow(File).to receive(:read).with(described_class::MANIFEST).and_return('{}')
      end

      it 'reports a graph that matches HEAD' do
        git[verify_synced] = "0123456789abcdef\n"
        git[%w[rev-parse --short HEAD]] = "0123456\n"
        expect { described_class.status([]) }
          .to output("graphify: current: the graph matches HEAD 0123456\n").to_stdout
      end

      it 'exits 3 when the graph is behind HEAD' do
        git.merge!(verify_synced => "fedcba\n", %w[diff --name-only fedcba HEAD] => "README.md\napp/a.rb\n",
                   %w[rev-list --count fedcba..HEAD] => "2\n")
        expect { described_class.status([]) }
          .to raise_error(an_object_having_attributes(status: 3))
          .and output(/2 commit\(s\) behind HEAD \(2 file\(s\) changed, 1 of them documents\)/).to_stdout
      end
    end
  end
end
