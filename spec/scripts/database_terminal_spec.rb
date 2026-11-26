require_relative 'support/script_helpers'

RSpec.describe DatabaseTerminal do
  include_context 'with ./go collaborators stubbed'

  it 'opens psql on the dev database by default' do
    expect(commands_run { described_class.connect([]) })
      .to eq(['docker compose -f docker-compose.yml -f docker-compose.dev.yml run db_client'])
  end

  it 'prints the db help for an unknown database', :aggregate_failures do
    expect { expect(commands_run { described_class.connect(['nope']) }).to be_empty }
      .to output(/psql/).to_stdout.and output(/Unrecognized command: nope/).to_stderr
  end
end
