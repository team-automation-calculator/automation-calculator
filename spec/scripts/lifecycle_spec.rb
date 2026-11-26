require_relative 'support/script_helpers'

RSpec.describe Lifecycle do
  include_context 'with ./go collaborators stubbed'

  let(:dev) { '-f docker-compose.yml -f docker-compose.dev.yml' }
  let(:production) { '-f docker-compose.yml -f docker-compose.production_http.yml' }

  before do
    env_with('USERNAME' => nil, 'USER' => 'steve')
    allow(ClearRailsPid).to receive(:clear_pid_file_if_it_exists)
    allow(EnvironmentVariables).to receive(:set_mock_production_vars)
  end

  def run(command, *args)
    commands_run(responses: responses) { described_class.public_send(command, *args) }
  end

  describe '.start' do
    it 'starts the dev service by default, clearing a stale server pid', :aggregate_failures do
      expect(run(:start, [])).to eq(["UID=501 docker compose #{dev} up -d dev"])
      expect(ClearRailsPid).to have_received(:clear_pid_file_if_it_exists)
    end

    it 'starts the production stack' do
      expect(run(:start, ['production'])).to eq(["docker compose #{production} up -d"])
    end

    it 'starts production with mock secrets to debug it', :aggregate_failures do
      expect(run(:start, ['debug_production'])).to eq(["docker compose #{production} up -d production"])
      expect(EnvironmentVariables).to have_received(:set_mock_production_vars)
    end

    it 'prints the start help for an unknown environment', :aggregate_failures do
      expect { expect(run(:start, ['nope'])).to be_empty }
        .to output(/debug_production/).to_stdout.and output(/Unrecognized command: nope/).to_stderr
    end
  end

  it 'builds the base and dev images, then runs bin/setup, on init' do
    expect(run(:init, []).last).to eq(%(UID=501 docker compose #{dev} run dev "/usr/src/app/bin/setup"))
  end

  it 'removes containers, images and volumes on clean' do
    expect(run(:clean)).to eq(['docker compose down --remove-orphans --rmi all --volumes'])
  end

  it 'stops, then starts dev, on restart' do
    expect(run(:restart)).to eq(['docker compose down --remove-orphans', "UID=501 docker compose #{dev} up -d dev"])
  end

  it 'removes every container on rm' do
    expect(run(:rm)).to eq(['docker compose down', 'docker ps -aq | xargs docker rm'])
  end

  it 'removes the dev image on rmi' do
    expect(run(:rmi)).to eq(['docker rmi automation-calculator_dev:latest'])
  end
end
