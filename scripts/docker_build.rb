# Build docker images for different environments
require './scripts/utils/get_uid.rb'
require './scripts/utils/git_short_sha.rb'

class DockerBuild
  DOCKER_ORG = 'automationcalculationsci'.freeze
  MULTI_PLATFORMS = 'linux/amd64,linux/arm64'.freeze

  class << self
    def build(cmds)
      sub_cmd = cmds.shift || 'dev'
      opts = build_opts(cmds)
      case sub_cmd
      when 'dev'  then build_dev_image(**opts)
      when 'ci'   then build_ci_image(**opts)
      when 'base' then build_base_image(**opts)
      when 'prod' then build_prod_image(**opts)
      else warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_base_image(no_cache: false, multi_platform: false)
      build_image(
        "#{DOCKER_ORG}/automation-calculator-base:0.5.4",
        'Dockerfile.base',
        'circleci',
        additional_build_arg: "--build-arg GIT_COMMIT=#{GitShortSha.read}",
        no_cache: no_cache,
        multi_platform: multi_platform
      )
    end

    def build_ci_image(no_cache: false, multi_platform: false)
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.ci',
        'circleci',
        additional_build_arg: "--build-arg GIT_COMMIT=#{GitShortSha.read}",
        no_cache: no_cache,
        multi_platform: multi_platform
      )
    end

    def build_dev_image(no_cache: false, multi_platform: false)
      build_image(
        'automation-calculator_dev',
        'Dockerfile.development',
        ENV['USERNAME'] || ENV['USER'],
        additional_build_arg: "--build-arg uid=#{GetUID.read_uid} " \
                              "--build-arg GIT_COMMIT=#{GitShortSha.read}",
        no_cache: no_cache,
        multi_platform: multi_platform
      )
    end

    def build_prod_image(no_cache: false, multi_platform: false)
      repo = "#{DOCKER_ORG}/automation-calculator"
      image = "#{repo}:latest"
      build_image(
        image,
        'Dockerfile.production',
        'circleci',
        additional_build_arg: "--build-arg GIT_COMMIT=#{GitShortSha.read}",
        no_cache: no_cache,
        multi_platform: multi_platform
      )
    end

    def build_image(tag, file, username, **opts)
      no_cache_flag = opts[:no_cache] ? '--no-cache' : ''
      add_arg = opts.fetch(:additional_build_arg, '')
      build_args = "--build-arg username=#{username} " \
                   "#{add_arg} #{no_cache_flag}"
      if opts[:multi_platform]
        ensure_buildx_builder
        run_buildx(tag, file, build_args)
      else
        run_docker_build(tag, file, build_args)
      end
    end

    def ensure_buildx_builder
      inspect = 'docker buildx inspect multiplatform > /dev/null 2>&1'
      return if system(inspect)

      system(
        'docker buildx create --name multiplatform ' \
        '--driver docker-container --bootstrap',
        exception: true
      )
      system('docker buildx use multiplatform', exception: true)
    end

    def build_opts(cmds)
      {
        no_cache: !cmds.delete('--no-cache').nil?,
        multi_platform: !cmds.delete('--multi-platform').nil?
      }
    end

    def run_buildx(tag, file, build_args)
      cmd = 'docker buildx build --builder multiplatform ' \
            "--platform #{MULTI_PLATFORMS} -t #{tag} " \
            "-f #{file} #{build_args} ."
      system(cmd, exception: true)
    end

    def run_docker_build(tag, file, build_args)
      cmd = "docker build -t #{tag} -f #{file} #{build_args} ."
      system(cmd, exception: true)
    end
  end
end
