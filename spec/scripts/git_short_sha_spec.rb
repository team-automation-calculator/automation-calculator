require_relative 'support/script_helpers'

RSpec.describe GitShortSha do
  it 'reads the short HEAD commit' do
    allow(described_class).to receive(:`).and_return("abc1234\n")
    expect(described_class.read).to eq('abc1234')
  end

  it 'is unknown outside a git checkout' do
    allow(described_class).to receive(:`).and_return('')
    expect(described_class.read).to eq('unknown')
  end
end
