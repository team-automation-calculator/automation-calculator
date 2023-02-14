# Build docker images for different environments
require './scripts/utils/get_uid.rb'

class DockerBuild
  class << self
    DOCKER_ORG = 'automationcalculationsci'.freeze

    def build(cmds)
      sub_cmd = cmds.shift || 'dev'

      case sub_cmd
      when 'dev'  then build_dev_image
      when 'ci'   then build_ci_image
      when 'base' then build_base_image
      when 'prod' then build_prod_image
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_base_image
      build_image(
        "#{DOCKER_ORG}/automation-calculator-base:0.4.0",
        'Dockerfile.base',
        'circleci'
      )
    end

    def build_ci_image
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.ci',
        'circleci'
      )
    end

    def build_dev_image
      build_image(
        'automation-calculator_dev',
        'Dockerfile.development',
        ENV['USERNAME'],
        "--build-arg uid=#{GetUID.read_uid}"
      )
    end

    def build_prod_image
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.production',
        'circleci'
      )
    end

    def build_image(tag, file, username, additional_build_arg = '')
      system(
        "docker build -t #{tag} -f #{file} " \
        "--build-arg username=#{username} #{additional_build_arg} .",
        exception: true
      )
    end
  end
end
