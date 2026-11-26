require './scripts/utils/runner'

# The docker buildx builder that multi-platform builds and pushes share.
class Buildx
  BUILDER = 'multiplatform'.freeze
  PLATFORMS = 'linux/amd64,linux/arm64'.freeze

  def initialize(runner)
    @runner = runner
  end

  def ensure_builder
    return if @runner.run("docker buildx inspect #{BUILDER} > /dev/null 2>&1")

    @runner.run("docker buildx create --name #{BUILDER} --driver docker-container --bootstrap", check: true)
    @runner.run("docker buildx use #{BUILDER}", check: true)
  end
end
