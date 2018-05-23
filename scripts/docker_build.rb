class DockerBuild
  class << self
    def build(cmds)
      sub_cmd = cmds.shift || 'dev'

      case sub_cmd
      when 'dev'
        build_dev_image
      when 'ci'
        build_ci_image
      when 'base'
        build_base_image
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_base_image
      build_image(
        'automationcalculators/automation-calculator-base:0.0.3',
        'Dockerfile.base',
        'circleci'
      )
    end

    def build_ci_image
      repo = 'automationcalculator/automation-calculator-rails'
      image = "#{repo}:latest"
      build_image(image, 'Dockerfile.ci', 'circleci', "--build-arg secret_key_base=#{ENV['SECRET_KEY_BASE']}")
    end

    def build_dev_image
      uid = `id -u`.strip
      build_image('automationcalculator_dev:latest', 'Dockerfile.development', ENV['USER'], "--build-arg uid=#{uid}")
    end

    def build_image(tag, file, username, additional_build_arg = '')
      system("docker build -t #{tag} -f #{file} --build-arg username=#{username} #{additional_build_arg} .")
    end
  end
end
