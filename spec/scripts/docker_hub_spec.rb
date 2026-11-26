require_relative 'support/script_helpers'

RSpec.describe DockerHub do
  include_context 'with ./go collaborators stubbed'

  let(:repo) { 'automationcalculationsci/automation-calculator' }
  let(:tags) { "-t #{repo}:0.9.6-970 -t #{repo}:latest" }
  let(:build_args) { '--build-arg username=circleci --build-arg GIT_COMMIT=abc1234' }

  before do
    env_with('SEMVER_MAJOR_VERSION' => '0', 'SEMVER_MINOR_VERSION' => '9',
             'SEMVER_PATCH' => '6', 'CIRCLE_BUILD_NUM' => '970')
    allow(FileUtils).to receive(:mkdir_p)
  end

  def push(*args)
    commands_run(responses: responses) { described_class.push_to_docker_hub(args) }
  end

  it 'pushes the prod image with its semver and latest tags by default' do
    expect(push).to eq(["docker push #{repo}:0.9.6-970", "docker push #{repo}:latest"])
  end

  it 'pushes the ci image with the same tags' do
    expect(push('ci')).to eq(["docker push #{repo}:0.9.6-970", "docker push #{repo}:latest"])
  end

  it 'pushes the base image at its pinned version' do
    expect(push('base')).to eq(["docker push #{repo}-base:0.11.0"])
  end

  it 'builds and pushes both architectures under --multi-platform' do
    expect(push('prod', '--multi-platform').last).to eq(
      "docker buildx build --platform linux/amd64,linux/arm64 #{tags} " \
      "-f Dockerfile.production #{build_args} --push ."
    )
  end

  describe '--digest-only' do
    let(:by_digest) do
      'docker buildx build --builder multiplatform --platform linux/arm64 ' \
        "-f Dockerfile.production #{build_args} " \
        '--output type=image,push-by-digest=true,name-canonical=true,push=true,' \
        "name=#{repo} --metadata-file tmp/digests/arm64.json ."
    end

    it 'pushes this host architecture by digest' do
      stub_const('RbConfig::CONFIG', RbConfig::CONFIG.merge('host_cpu' => 'aarch64'))
      expect(push('--digest-only').last).to eq(by_digest)
    end
  end

  it 'refuses --digest-only on a CPU outside the manifest' do
    stub_const('RbConfig::CONFIG', RbConfig::CONFIG.merge('host_cpu' => 'sparc'))
    expect { push('--digest-only') }.to raise_error(KeyError)
  end

  describe '--manifest' do
    before do
      allow(File).to receive(:read).and_call_original
      %w[amd64 arm64].each do |arch|
        allow(File).to receive(:read).with("tmp/digests/#{arch}.json")
                                     .and_return(%({"containerimage.digest":"sha256:#{arch}"}))
      end
    end

    it 'joins the recorded digests into one tagged manifest' do
      expect(push('--manifest')).to eq(
        ["docker buildx imagetools create #{tags} #{repo}@sha256:amd64 #{repo}@sha256:arm64"]
      )
    end

    it 'names the architecture whose digest is missing' do
      allow(File).to receive(:read).with('tmp/digests/arm64.json').and_raise(Errno::ENOENT)
      expect { push('--manifest') }.to raise_error(/No arm64 digest/)
    end
  end

  it 'tags latest with the semver tag' do
    expect(commands_run { described_class.tag_latest_with_semver })
      .to eq(["docker tag #{repo}:latest #{repo}:0.9.6-970"])
  end

  it 'warns about an unknown image and runs nothing', :aggregate_failures do
    expect { expect(push('nope')).to be_empty }.to output(/Unrecognized image: nope/).to_stderr
  end
end
