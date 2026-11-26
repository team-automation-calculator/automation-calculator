require_relative 'support/script_helpers'

RSpec.describe Shell do
  include_context 'with a recording runner'

  def shell(*args, env: { 'USER' => 'steve' })
    described_class.new(runner: runner, env: env).shell(args)
    runner.commands
  end

  it 'opens bash in the dev container by default' do
    expect(shell).to eq(['UID=501 docker compose -f docker-compose.yml -f docker-compose.dev.yml run dev /bin/bash'])
  end

  it 'opens bash in the ci container' do
    expect(shell('ci')).to eq(
      ['USER=steve docker compose -f docker-compose.yml -f docker-compose.ci.yml run --entrypoint /bin/bash ci']
    )
  end

  it 'runs the ci shell as circleci when USER is unset' do
    expect(shell('ci', env: {}).first).to start_with('USER=circleci ')
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
