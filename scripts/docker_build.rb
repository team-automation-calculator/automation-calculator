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
        'automationcalculators/automation-calculator-base:0.0.2',
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
      build_image('automationcalculator_dev:latest', 'Dockerfile.development')
    end

    def build_image(tag, file, username = ENV['USER'], additional_build_arg = '')
      sys_call = "docker build -t #{tag} -f #{file} --build-arg username=#{username} #{additional_build_arg} ."
      puts sys_call
      system(sys_call)
    end
  end
end
