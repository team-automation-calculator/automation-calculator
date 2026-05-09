# Build docker images for different environments
require './scripts/utils/get_uid.rb'

class DockerBuild
  class << self
    DOCKER_ORG = 'automationcalculationsci'.freeze
    MULTI_PLATFORMS = 'linux/amd64,linux/arm64'.freeze

    def build(cmds)
      sub_cmd = cmds.shift || 'dev'
      no_cache = cmds.delete('--no-cache') != nil
      multi_platform = cmds.delete('--multi-platform') != nil
      push = cmds.delete('--push') != nil

      case sub_cmd
      when 'dev'  then build_dev_image(no_cache: no_cache, multi_platform: multi_platform, push: push)
      when 'ci'   then build_ci_image(no_cache: no_cache, multi_platform: multi_platform, push: push)
      when 'base' then build_base_image(no_cache: no_cache, multi_platform: multi_platform, push: push)
      when 'prod' then build_prod_image(no_cache: no_cache, multi_platform: multi_platform, push: push)
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_base_image(no_cache: false, multi_platform: false, push: false)
      build_image(
        "#{DOCKER_ORG}/automation-calculator-base:0.5.3",
        'Dockerfile.base',
        'circleci',
        no_cache: no_cache,
        multi_platform: multi_platform,
        push: push
      )
    end

    def build_ci_image(no_cache: false, multi_platform: false, push: false)
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.ci',
        'circleci',
        no_cache: no_cache,
        multi_platform: multi_platform,
        push: push
      )
    end

    def build_dev_image(no_cache: false, multi_platform: false, push: false)
      build_image(
        'automation-calculator_dev',
        'Dockerfile.development',
        ENV['USERNAME'],
        "--build-arg uid=#{GetUID.read_uid}",
        no_cache: no_cache,
        multi_platform: multi_platform,
        push: push
      )
    end

    def build_prod_image(no_cache: false, multi_platform: false, push: false)
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.production',
        'circleci',
        no_cache: no_cache,
        multi_platform: multi_platform,
        push: push
      )
    end

    def build_image(tag, file, username, additional_build_arg = '', no_cache: false, multi_platform: false, push: false)
      no_cache_flag = no_cache ? '--no-cache' : ''
      if multi_platform
        ensure_buildx_builder
        push_flag = push ? '--push' : ''
        system(
          "docker buildx build --platform #{MULTI_PLATFORMS} " \
          "-t #{tag} -f #{file} " \
          "--build-arg username=#{username} #{additional_build_arg} #{no_cache_flag} #{push_flag} .",
          exception: true
        )
      else
        system(
          "docker build -t #{tag} -f #{file} " \
          "--build-arg username=#{username} #{additional_build_arg} #{no_cache_flag} .",
          exception: true
        )
      end
    end

    def ensure_buildx_builder
      builder_exists = system('docker buildx inspect multiplatform > /dev/null 2>&1')
      return if builder_exists

      system(
        'docker buildx create --name multiplatform --driver docker-container --bootstrap',
        exception: true
      )
      system('docker buildx use multiplatform', exception: true)
    end
  end
end
