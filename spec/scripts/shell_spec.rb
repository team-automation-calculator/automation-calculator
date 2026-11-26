require_relative 'support/script_helpers'

RSpec.describe Shell do
  include_context 'with ./go collaborators stubbed'

  before { env_with('USER' => 'steve') }

  def shell(*args)
    commands_run(responses: responses) { described_class.shell(args) }
  end

  it 'opens bash in the dev container by default' do
    expect(shell).to eq(['UID=501 docker compose -f docker-compose.yml -f docker-compose.dev.yml run dev /bin/bash'])
  end

  it 'opens bash in the ci container' do
    expect(shell('ci')).to eq(
      ['USER=steve docker compose -f docker-compose.yml -f docker-compose.ci.yml run --entrypoint /bin/bash ci']
    )
  end

  it 'opens bash in the production image' do
    expect(shell('production')).to eq(
      ['docker compose -f docker-compose.yml -f docker-compose.production_http.yml run production /bin/bash']
    )
  end

  it 'prints the shell help for an unknown environment', :aggregate_failures do
    expect { expect(shell('nope')).to be_empty }
      .to output(/production/).to_stdout.and output(/Unrecognized command: nope/).to_stderr
  end
end
