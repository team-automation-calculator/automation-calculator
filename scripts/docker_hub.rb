# Interract with the DockerHub
class DockerHub
  REPO = 'automationcalculationsci/automation-calculator'.freeze
  REPO_BASE = 'automationcalculationsci/automation-calculator-base'.freeze
  BASE_VERSION = '0.5.4'.freeze

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
      multi_platform = !cmds.delete('--multi-platform').nil?
      config = image_configs[sub_cmd]
      return warn("Unrecognized image: #{sub_cmd}") if config.nil?

      multi_platform ? push_multi_platform(config) : push_tags(config)
    end

    private

    def sub_cmd_from(cmds)
      !cmds.first.nil? && !cmds.first.start_with?('--') ? cmds.shift : 'prod'
    end

    def push_tags(config)
      config[:tags].each { |tag| system("docker push #{tag}") }
    end

    def image_configs
      tags = [image_w_semver, latest_tag]
      {
        'ci' => { tags: tags, file: 'Dockerfile.ci', username: 'circleci' },
        'prod' => { tags: tags, file: 'Dockerfile.production',
                    username: 'circleci' },
        'base' => { tags: ["#{REPO_BASE}:#{BASE_VERSION}"],
                    file: 'Dockerfile.base', username: 'circleci' }
      }
    end

    def push_multi_platform(config)
      DockerBuild.ensure_buildx_builder
      tags_flags = config[:tags].map { |t| "-t #{t}" }.join(' ')
      system(
        "docker buildx build --platform #{DockerBuild::MULTI_PLATFORMS} " \
        "#{tags_flags} -f #{config[:file]} " \
        "--build-arg username=#{config[:username]} --push .",
        exception: true
      )
    end
  end
end
