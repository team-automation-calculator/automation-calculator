require_relative 'support/script_helpers'

RSpec.describe Logs do
  include_context 'with a recording runner'

  it 'follows the dev service logs' do
    described_class.new(runner: runner).logs
    expect(runner.commands).to eq(['docker compose logs --follow dev'])
  end
end
