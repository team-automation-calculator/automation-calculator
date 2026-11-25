require_relative '../../scripts/graphify'
require_relative '../../scripts/graphify_status'

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
end
