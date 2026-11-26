# ./go push [prod|ci|base] [--multi-platform|--digest-only|--manifest]
# and ./go tag.
require 'fileutils'
require 'json'
require 'rbconfig'
require './scripts/utils/buildx'
require './scripts/utils/docker_images'
require './scripts/utils/runner'

class DockerHub
  PUSH_MODES = {
    '--multi-platform' => :push_multi_platform,
    '--digest-only' => :push_digest_only,
    '--manifest' => :push_manifest
  }.freeze
  # Where --digest-only records what it pushed, one file per architecture.
  # tmp/ is gitignored and excluded from the Docker build context.
  DIGEST_DIR = 'tmp/digests'.freeze
  BY_DIGEST_OUTPUT = 'type=image,push-by-digest=true,name-canonical=true,push=true'.freeze
  MANIFEST_ARCHS = %w[amd64 arm64].freeze
  HOST_CPU_ARCHS = { 'x86_64' => 'amd64', 'aarch64' => 'arm64' }.freeze

  def initialize(runner: Runner.new, images: DockerImages.new(host: Host.new(runner)),
                 host_cpu: RbConfig::CONFIG['host_cpu'])
    @runner = runner
    @images = images
    @host_cpu = host_cpu
  end

  def push(cmds)
    name = image_name(cmds)
    mode = PUSH_MODES.find { |flag, _| cmds.delete(flag) }
    image = @images.pushable(name)
    return warn("Unrecognized image: #{name}") unless image

    send(mode ? mode.last : :push_tags, image)
  end

  def tag_latest_with_semver
    @runner.run("docker tag #{@images.latest_tag} #{@images.semver_tag}")
  end

  private

  # A leading image name, taken off cmds; prod when the first word is a flag.
  def image_name(cmds)
    first = cmds.first
    first.nil? || first.start_with?('--') ? 'prod' : cmds.shift
  end

  def push_tags(image)
    image.push_tags.each { |tag| @runner.run("docker push #{tag}") }
  end

  # Slow: the non-native architecture is built under emulation.
  def push_multi_platform(image)
    Buildx.new(@runner).ensure_builder
    @runner.run("docker buildx build --platform #{Buildx::PLATFORMS} #{image.tag_flags} " \
                "-f #{image.file} #{@images.build_args(image)} --push .", check: true)
  end

  # Build the image for this host's own architecture (no emulation) and push
  # it untagged, addressed only by its digest, which is recorded in
  # tmp/digests/<arch>.json for --manifest.
  def push_digest_only(image)
    Buildx.new(@runner).ensure_builder
    @runner.run("docker buildx build --builder #{Buildx::BUILDER} --platform linux/#{host_arch} " \
                "-f #{image.file} #{@images.build_args(image)} " \
                "--output #{BY_DIGEST_OUTPUT},name=#{image.repo} --metadata-file #{digest_file(host_arch)} .",
                check: true)
  end

  # Join the per-architecture images pushed with --digest-only into one
  # multi-arch manifest and give it the image's tags. Nothing is rebuilt.
  def push_manifest(image)
    sources = MANIFEST_ARCHS.map { |arch| "#{image.repo}@#{digest(arch)}" }
    @runner.run("docker buildx imagetools create #{image.tag_flags} #{sources.join(' ')}", check: true)
  end

  # Raises KeyError on a CPU that is neither half of the manifest.
  def host_arch
    HOST_CPU_ARCHS.fetch(@host_cpu)
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
end
