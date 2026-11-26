# ./go build [dev|ci|base|prod] [--no-cache] [--multi-platform]
require './scripts/utils/buildx'
require './scripts/utils/compose_files'
require './scripts/utils/docker_images'
require './scripts/utils/runner'

class DockerBuild
  FLAGS = %w[--no-cache --multi-platform].freeze

  def initialize(runner: Runner.new, images: DockerImages.new(host: Host.new(runner)))
    @runner = runner
    @images = images
  end

  def build(cmds)
    name = cmds.shift || 'dev'
    image = @images[name]
    return warn("Unrecognized command: #{name}") unless image

    args = @images.build_args(image)
    args += ' --no-cache' if cmds.delete('--no-cache')
    cmds.delete('--multi-platform') ? build_multi_platform(image, args) : build_native(image, args)
  end

  private

  def build_native(image, args)
    service = image.compose_service
    command = if service
                "docker compose #{ComposeFiles.flags(service)} build #{args} #{service}"
              else
                "docker build -t #{image.tag} -f #{image.file} #{args} ."
              end
    @runner.run(command, check: true)
  end

  # Both architectures, kept in the buildx builder's cache for a later push.
  def build_multi_platform(image, args)
    Buildx.new(@runner).ensure_builder
    @runner.run("docker buildx build --builder #{Buildx::BUILDER} --platform #{Buildx::PLATFORMS} " \
                "-t #{image.tag} -f #{image.file} #{args} .", check: true)
  end
end
