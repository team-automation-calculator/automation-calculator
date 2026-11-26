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

  describe '#status' do
    include_context 'with graphify on a recording runner'

    let(:status) { described_class.new(graphify: graphify) }
    let(:verify_synced) { ['rev-parse', '--verify', '--quiet', '0123456789abcdef^{commit}'] }

    it 'says nothing in --brief mode in a throwaway environment', :aggregate_failures do
      env['CI'] = '1'
      expect { expect(status.status(['--brief'])).to eq(0) }.not_to output.to_stdout
    end

    it 'says nothing in --brief mode with no graph', :aggregate_failures do
      graph_exists(false)
      expect { expect(status.status(['--brief'])).to eq(0) }.not_to output.to_stdout
    end

    it 'is 1 with no graph', :aggregate_failures do
      graph_exists(false)
      expect { expect(status.status([])).to eq(1) }.to output(/no graphify-out/).to_stdout
    end

    context 'with a graph' do
      before do
        graph_exists(true)
        allow(File).to receive(:file?).with(Graphify::SYNCED_FILE).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(Graphify::SYNCED_FILE).and_return("0123456789abcdef\n")
        allow(File).to receive(:read).with(described_class::MANIFEST).and_return('{"README.md":{}}')
      end

      it 'reports a graph that matches HEAD', :aggregate_failures do
        git_answers(verify_synced => "0123456789abcdef\n", %w[rev-parse --short HEAD] => "0123456\n")
        allow(File).to receive(:read).with(described_class::MANIFEST).and_return('{}')
        expect { expect(status.status([])).to eq(0) }
          .to output("graphify: current: the graph matches HEAD 0123456\n").to_stdout
      end

      it 'is 3 when the graph is behind HEAD', :aggregate_failures do
        git_answers(verify_synced => "fedcba\n", %w[diff --name-only fedcba HEAD] => "README.md\napp/a.rb\n",
                    %w[rev-list --count fedcba..HEAD] => "2\n")
        expect { expect(status.status([])).to eq(3) }
          .to output(/2 commit\(s\) behind HEAD \(2 file\(s\) changed, 1 of them documents\).*README.md/).to_stdout
      end

      it 'prints the same line in --brief mode, and is 0', :aggregate_failures do
        git_answers(verify_synced => "0123456789abcdef\n")
        expect { expect(status.status(['--brief'])).to eq(0) }
          .to output(%r{1 document\(s\) wait for the LLM pass \(/graphify --update\): README.md}).to_stdout
      end

      it 'says so when the recorded commit is not in this checkout' do
        expect { status.status([]) }.to output(/built from a commit this checkout does not have/).to_stdout
      end

      it 'lists five pending documents, then an ellipsis' do
        manifest = %w[a b c d e f].to_h { |name| ["#{name}.md", {}] }
        allow(File).to receive(:read).with(described_class::MANIFEST).and_return(manifest.to_json)
        expect { status.status(['--brief']) }
          .to output(/6 document\(s\).*: a.md, b.md, c.md, d.md, e.md \.\.\./).to_stdout
      end

      it 'leaves out the documents when the manifest is unreadable' do
        git_answers(verify_synced => "0123456789abcdef\n", %w[rev-parse --short HEAD] => "0123456\n")
        allow(File).to receive(:read).with(described_class::MANIFEST).and_raise(Errno::ENOENT)
        expect { status.status([]) }.to output(/current: the graph matches HEAD/).to_stdout
      end
    end

    context 'with a graph but no recorded refresh' do
      before do
        graph_exists(true)
        allow(File).to receive(:file?).with(Graphify::SYNCED_FILE).and_return(false)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(described_class::MANIFEST).and_return('{}')
        git_answers(verify_synced => "0123456789abcdef\n", %w[rev-parse --short HEAD] => "0123456\n")
      end

      it 'reads the commit graph.json was built at' do
        allow(File).to receive(:read).with(Graphify::GRAPH).and_return('{"built_at_commit":"0123456789abcdef"}')
        expect { status.status([]) }.to output(/current: the graph matches HEAD 0123456/).to_stdout
      end

      it 'treats an unreadable graph.json as built from an unknown commit' do
        allow(File).to receive(:read).with(Graphify::GRAPH).and_return('not json')
        expect { status.status([]) }.to output(/built from a commit this checkout does not have/).to_stdout
      end
    end
  end
end
