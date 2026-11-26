require_relative 'support/script_helpers'

RSpec.describe Lifecycle do
  include_context 'with a recording runner'

  let(:dev) { '-f docker-compose.yml -f docker-compose.dev.yml' }
  let(:production) { '-f docker-compose.yml -f docker-compose.production_http.yml' }
  let(:env) { { 'USER' => 'steve' } }
  let(:docker_build) { instance_double(DockerBuild, build: nil) }
  let(:lifecycle) { described_class.new(runner: runner, env: env, docker_build: docker_build) }

  before { allow(ClearRailsPid).to receive(:clear_pid_file_if_it_exists) }

  def run(command, *args)
    lifecycle.public_send(command, *args)
    runner.commands
  end

  describe '#start' do
    it 'starts the dev service by default, clearing a stale server pid', :aggregate_failures do
      expect(run(:start, [])).to eq(["UID=501 docker compose #{dev} up -d dev"])
      expect(ClearRailsPid).to have_received(:clear_pid_file_if_it_exists)
    end

    it 'starts the production stack' do
      expect(run(:start, ['production'])).to eq(["docker compose #{production} up -d"])
    end

    it 'starts production with mock secrets for what the environment lacks', :aggregate_failures do
      expect(run(:start, ['debug_production'])).to eq(["docker compose #{production} up -d production"])
      expect(runner.calls.last.env)
        .to include('DOCKER_REPO_USER' => 'automationcalculator', 'SECRET_KEY_BASE' => /\A\h+\z/)
    end

    it 'prints the start help for an unknown environment', :aggregate_failures do
      expect { expect(run(:start, ['nope'])).to be_empty }
        .to output(/debug_production/).to_stdout.and output(/Unrecognized command: nope/).to_stderr
    end
  end

  it 'builds the base and dev images, then runs bin/setup, on init', :aggregate_failures do
    expect(run(:init, ['--no-cache'])).to eq([%(UID=501 docker compose #{dev} run dev "/usr/src/app/bin/setup")])
    expect(docker_build).to have_received(:build).with(['base']).ordered
    expect(docker_build).to have_received(:build).with(['--no-cache']).ordered
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

  it 'stops the containers and removes the images this checkout built on rmi' do
    expect(run(:rmi)).to eq(["docker compose #{dev} down --rmi local"])
  end
end
