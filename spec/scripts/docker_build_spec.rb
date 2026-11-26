require_relative 'support/script_helpers'

RSpec.describe DockerBuild do
  include_context 'with ./go collaborators stubbed'

  let(:repo) { 'automationcalculationsci/automation-calculator' }

  before { env_with('USERNAME' => nil, 'USER' => 'steve') }

  def build(*args)
    commands_run(responses: responses) { described_class.build(args) }
  end

  it 'builds the dev image by default, as the current user' do
    expect(build).to eq(
      ['docker build -t automation-calculator_dev -f Dockerfile.development ' \
       '--build-arg username=steve --build-arg uid=501 --build-arg GIT_COMMIT=abc1234 .']
    )
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
  end

  it 'creates the buildx builder when it does not exist yet' do
    allow(described_class).to receive(:system).and_return(false, true, true)
    described_class.ensure_buildx_builder
    expect(described_class).to have_received(:system).with('docker buildx use multiplatform', exception: true)
  end

  it 'warns about an unknown image and runs nothing', :aggregate_failures do
    expect { expect(build('nope')).to be_empty }.to output(/Unrecognized command: nope/).to_stderr
  end
end
