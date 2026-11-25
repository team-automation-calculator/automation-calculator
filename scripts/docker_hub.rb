require 'fileutils'
require 'json'
require 'rbconfig'

# Interract with the DockerHub
class DockerHub
  REPO = 'automationcalculationsci/automation-calculator'.freeze
  REPO_BASE = 'automationcalculationsci/automation-calculator-base'.freeze
  BASE_VERSION = '0.11.0'.freeze
  PUSH_MODES = {
    '--multi-platform' => :push_multi_platform,
    '--digest-only' => :push_digest_only,
    '--manifest' => :push_manifest
  }.freeze
  # Where --digest-only records what it pushed, one file per architecture.
  # tmp/ is gitignored and excluded from the Docker build context.
  DIGEST_DIR = 'tmp/digests'.freeze
  BY_DIGEST_OUTPUT =
    'type=image,push-by-digest=true,name-canonical=true,push=true'.freeze
  MANIFEST_ARCHS = %w[amd64 arm64].freeze
  HOST_CPU_ARCHS = { 'x86_64' => 'amd64', 'aarch64' => 'arm64' }.freeze

  class << self
    def semver_tag
      "#{ENV['SEMVER_MAJOR_VERSION']}."\
      "#{ENV['SEMVER_MINOR_VERSION']}."\
      "#{ENV['SEMVER_PATCH']}-"\
      "#{ENV['CIRCLE_BUILD_NUM']}"
    end

    def image_w_semver
      "#{REPO}:#{semver_tag}"
    end

    def tag_latest_with_semver
      system("docker tag #{latest_tag} #{image_w_semver}")
    end

    def latest_tag
      "#{REPO}:latest"
    end

    def push_to_docker_hub(cmds = [])
      sub_cmd = sub_cmd_from(cmds)
      mode = PUSH_MODES.find { |flag, _| cmds.delete(flag) }&.last
      config = image_configs[sub_cmd]
      return warn("Unrecognized image: #{sub_cmd}") if config.nil?

      send(mode || :push_tags, config)
    end

    private

    # Build the image for this host's own architecture (no emulation) and
    # push it to Docker Hub untagged, addressed only by its digest. The
    # digest is recorded in tmp/digests/<arch>.json for --manifest.
    def push_digest_only(config)
      DockerBuild.ensure_buildx_builder
      system(
        'docker buildx build --builder multiplatform ' \
        "--platform linux/#{host_arch} -f #{config[:file]} " \
        "--build-arg username=#{config[:username]} " \
        "--build-arg GIT_COMMIT=#{GitShortSha.read} " \
        "--output #{BY_DIGEST_OUTPUT},name=#{config[:repo]} " \
        "--metadata-file #{digest_file(host_arch)} .",
        exception: true
      )
    end

    # Join the per-architecture images pushed with --digest-only into one
    # multi-arch manifest and give it the image's tags. Nothing is rebuilt.
    def push_manifest(config)
      tags_flags = config[:tags].map { |t| "-t #{t}" }.join(' ')
      sources = MANIFEST_ARCHS.map { |arch| "#{config[:repo]}@#{digest(arch)}" }
      system(
        "docker buildx imagetools create #{tags_flags} #{sources.join(' ')}",
        exception: true
      )
    end

    # Raises KeyError on a CPU that is neither half of the manifest.
    def host_arch
      HOST_CPU_ARCHS.fetch(RbConfig::CONFIG['host_cpu'])
    end

    def digest_file(arch)
      FileUtils.mkdir_p(DIGEST_DIR)
      File.join(DIGEST_DIR, "#{arch}.json")
    end

    def digest(arch)
      JSON.parse(File.read(digest_file(arch))).fetch('containerimage.digest')
    rescue Errno::ENOENT
      raise "No #{arch} digest: run ./go push --digest-only on #{arch} first"
    end

    def sub_cmd_from(cmds)
      !cmds.first.nil? && !cmds.first.start_with?('--') ? cmds.shift : 'prod'
    end

    def push_tags(config)
      config[:tags].each { |tag| system("docker push #{tag}") }
    end

    def image_configs
      tags = [image_w_semver, latest_tag]
      {
        'ci' => { repo: REPO, tags: tags, file: 'Dockerfile.ci',
                  username: 'circleci' },
        'prod' => { repo: REPO, tags: tags, file: 'Dockerfile.production',
                    username: 'circleci' },
        'base' => { repo: REPO_BASE, tags: ["#{REPO_BASE}:#{BASE_VERSION}"],
                    file: 'Dockerfile.base', username: 'circleci' }
      }
    end

    def push_multi_platform(config)
      DockerBuild.ensure_buildx_builder
      tags_flags = config[:tags].map { |t| "-t #{t}" }.join(' ')
      system(
        "docker buildx build --platform #{DockerBuild::MULTI_PLATFORMS} " \
        "#{tags_flags} -f #{config[:file]} " \
        "--build-arg username=#{config[:username]} " \
        "--build-arg GIT_COMMIT=#{GitShortSha.read} --push .",
        exception: true
      )
    end
  end
end
