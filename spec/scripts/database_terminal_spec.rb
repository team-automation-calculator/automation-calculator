require_relative 'support/script_helpers'

RSpec.describe DatabaseTerminal do
  include_context 'with a recording runner'

  def connect(*args)
    described_class.new(runner: runner).connect(args)
    runner.commands
  end

  it 'opens psql on the dev database by default' do
    expect(connect).to eq(['docker compose -f docker-compose.yml -f docker-compose.dev.yml run db_client'])
  end

  it 'prints the db help for an unknown database', :aggregate_failures do
    expect { expect(connect('nope')).to be_empty }
      .to output(/psql/).to_stdout.and output(/Unrecognized command: nope/).to_stderr
  end
end
