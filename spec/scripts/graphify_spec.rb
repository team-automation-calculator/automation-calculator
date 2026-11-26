require_relative '../../scripts/graphify'

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
end
