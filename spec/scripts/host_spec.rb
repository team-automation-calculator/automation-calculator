require_relative 'support/script_helpers'

RSpec.describe Host do
  it 'reads the current user id' do
    expect(described_class.new(RecordingRunner.new(outputs: { 'id -u' => "501\n" })).uid).to eq('501')
  end

  it 'reads the short HEAD commit' do
    runner = RecordingRunner.new(outputs: { 'git rev-parse --short HEAD 2>/dev/null' => "abc1234\n" })
    expect(described_class.new(runner).git_short_sha).to eq('abc1234')
  end

  it 'reports an unknown commit outside a git checkout' do
    expect(described_class.new(RecordingRunner.new).git_short_sha).to eq('unknown')
  end
end
