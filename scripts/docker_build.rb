# Build docker images for different environments
require './scripts/utils/get_uid.rb'

class DockerBuild
  class << self
    DOCKER_ORG = 'automationcalculationsci'.freeze

    def build(cmds)
      sub_cmd = cmds.shift || 'dev'
      no_cache = cmds.delete('--no-cache') != nil

      case sub_cmd
      when 'dev'  then build_dev_image(no_cache: no_cache)
      when 'ci'   then build_ci_image(no_cache: no_cache)
      when 'base' then build_base_image(no_cache: no_cache)
      when 'prod' then build_prod_image(no_cache: no_cache)
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_base_image(no_cache: false)
      build_image(
        "#{DOCKER_ORG}/automation-calculator-base:0.5.3",
        'Dockerfile.base',
        'circleci',
        no_cache: no_cache
      )
    end

    def build_ci_image(no_cache: false)
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.ci',
        'circleci',
        no_cache: no_cache
      )
    end

    def build_dev_image(no_cache: false)
      build_image(
        'automation-calculator_dev',
        'Dockerfile.development',
        ENV['USERNAME'],
        "--build-arg uid=#{GetUID.read_uid}",
        no_cache: no_cache
      )
    end

    def build_prod_image(no_cache: false)
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.production',
        'circleci',
        no_cache: no_cache
      )
    end

    def build_image(tag, file, username, additional_build_arg = '', no_cache: false)
      no_cache_flag = no_cache ? '--no-cache' : ''
      system(
        "docker build -t #{tag} -f #{file} " \
        "--build-arg username=#{username} #{additional_build_arg} #{no_cache_flag} .",
        exception: true
      )
    end
  end
end
