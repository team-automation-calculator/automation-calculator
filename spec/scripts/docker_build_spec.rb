require_relative 'support/script_helpers'

RSpec.describe DockerBuild do
  include_context 'with a recording runner'

  let(:repo) { 'automationcalculationsci/automation-calculator' }
  let(:images) { DockerImages.new(env: { 'USER' => 'steve' }, host: Host.new(runner)) }

  def build(*args)
    described_class.new(runner: runner, images: images).build(args)
    runner.commands
  end

  it 'builds the dev image by default, through compose, as the current user' do
    expect(build).to eq(
      ['docker compose -f docker-compose.yml -f docker-compose.dev.yml build ' \
       '--build-arg username=steve --build-arg uid=501 --build-arg GIT_COMMIT=abc1234 dev']
    )
  end

  it 'passes --no-cache through to the compose build' do
    expect(build('dev', '--no-cache').first).to end_with('GIT_COMMIT=abc1234 --no-cache dev')
  end

  it 'builds the ci image' do
    expect(build('ci')).to eq(
      ["docker build -t #{repo}:latest -f Dockerfile.ci " \
       '--build-arg username=circleci --build-arg GIT_COMMIT=abc1234 .']
    )
  end

  it 'builds the base image at its pinned version' do
    expect(build('base')).to eq(
      ["docker build -t #{repo}-base:0.11.0 -f Dockerfile.base " \
       '--build-arg username=circleci --build-arg GIT_COMMIT=abc1234 .']
    )
  end

  it 'builds the prod image' do
    expect(build('prod')).to eq(
      ["docker build -t #{repo}:latest -f Dockerfile.production " \
       '--build-arg username=circleci --build-arg GIT_COMMIT=abc1234 .']
    )
  end

  it 'passes --no-cache through' do
    expect(build('ci', '--no-cache').first).to end_with('GIT_COMMIT=abc1234 --no-cache .')
  end

  describe '--multi-platform' do
    let(:buildx) do
      'docker buildx build --builder multiplatform --platform linux/amd64,linux/arm64 ' \
        "-t #{repo}:latest -f Dockerfile.production " \
        '--build-arg username=circleci --build-arg GIT_COMMIT=abc1234 .'
    end

    it 'builds both architectures with buildx' do
      expect(build('prod', '--multi-platform')).to eq(['docker buildx inspect multiplatform > /dev/null 2>&1', buildx])
    end

    it 'creates the buildx builder when it does not exist yet' do
      runner = RecordingRunner.new(results: { 'docker buildx inspect multiplatform > /dev/null 2>&1' => false })
      Buildx.new(runner).ensure_builder
      expect(runner.commands.last(2)).to eq(['docker buildx create --name multiplatform --driver docker-container ' \
                                             '--bootstrap', 'docker buildx use multiplatform'])
    end
  end

  it 'warns about an unknown image and runs nothing', :aggregate_failures do
    expect { expect(build('nope')).to be_empty }.to output(/Unrecognized command: nope/).to_stderr
  end
end
