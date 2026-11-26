require './scripts/utils/host'

# The images ./go builds and pushes, one entry each. DockerBuild and
# DockerHub both read them, so a new image or a base version bump is one
# edit here.
class DockerImages
  REPO = 'automationcalculationsci/automation-calculator'.freeze
  BASE_REPO = "#{REPO}-base".freeze
  BASE_VERSION = '0.11.0'.freeze

  # tag: what `docker build` names it; push_tags: what `./go push` publishes
  # (none for an image that is never pushed); uid: built for the current user;
  # compose_service: the docker compose service that runs it, which builds
  # and names the image itself (one per checkout), so `./go build` goes
  # through compose and refreshes the image `./go test` and `start` run.
  Image = Struct.new(:tag, :file, :username, :repo, :push_tags, :uid, :compose_service, keyword_init: true) do
    def pushable?
      !push_tags.empty?
    end

    def tag_flags
      push_tags.map { |tag| "-t #{tag}" }.join(' ')
    end
  end

  def initialize(env: ENV, host: Host.new)
    @env = env
    @host = host
  end

  def [](name)
    images[name]
  end

  # The named image when ./go push publishes it, else nil.
  def pushable(name)
    image = images[name]
    image if image&.pushable?
  end

  def names
    images.keys
  end

  def build_args(image)
    args = ["username=#{image.username}"]
    args << "uid=#{@host.uid}" if image.uid
    args << "GIT_COMMIT=#{@host.git_short_sha}"
    args.map { |arg| "--build-arg #{arg}" }.join(' ')
  end

  def latest_tag
    "#{REPO}:latest"
  end

  # MAJOR.MINOR.PATCH-BUILD, from CircleCI's environment.
  def semver_tag
    "#{REPO}:#{@env['SEMVER_MAJOR_VERSION']}.#{@env['SEMVER_MINOR_VERSION']}." \
      "#{@env['SEMVER_PATCH']}-#{@env['CIRCLE_BUILD_NUM']}"
  end

  private

  def images
    @images ||= {
      'dev' => dev_image,
      'ci' => app_image('Dockerfile.ci'),
      'base' => Image.new(tag: "#{BASE_REPO}:#{BASE_VERSION}", file: 'Dockerfile.base', username: 'circleci',
                          repo: BASE_REPO, push_tags: ["#{BASE_REPO}:#{BASE_VERSION}"]),
      'prod' => app_image('Dockerfile.production')
    }
  end

  # Built for the current user; tag is the name a --multi-platform build gives
  # it, as compose names the image it builds after the checkout.
  def dev_image
    Image.new(tag: 'automation-calculator_dev', file: 'Dockerfile.development', push_tags: [],
              username: @env['USERNAME'] || @env['USER'], uid: true, compose_service: 'dev')
  end

  def app_image(file)
    Image.new(tag: latest_tag, file: file, username: 'circleci', repo: REPO, push_tags: [semver_tag, latest_tag])
  end
end
