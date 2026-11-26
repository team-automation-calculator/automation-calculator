require_relative 'support/script_helpers'

RSpec.describe GetUID do
  it 'reads the current user id' do
    allow(described_class).to receive(:`).with('id -u').and_return("501\n")
    expect(described_class.read_uid).to eq('501')
  end
end
