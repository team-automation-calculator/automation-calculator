require_relative 'support/script_helpers'

RSpec.describe Logs do
  include_context 'with ./go collaborators stubbed'

  it 'follows the dev service logs' do
    expect(commands_run { described_class.logs }).to eq(['docker compose logs --follow dev'])
  end
end
