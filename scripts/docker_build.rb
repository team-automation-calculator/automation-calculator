class DockerBuild
  class << self
    def build(cmds)
      sub_cmd = cmds.shift || 'dev'

      case sub_cmd
      when 'dev'
        build_image('automationcalculator_dev:latest', 'Dockerfile.development')
      when 'ci'
        repo = 'automationcalculator/automation-calculator-rails'
        image = "#{repo}:latest"
        build_image(image, 'Dockerfile.ci')
      when 'base'
        build_image(
          'automationcalculators/automation-calculator-base:0.0.2',
          'Dockerfile.base',
          'circleci',
          "--build-arg secret_key_base=#{ENV['SECRET_KEY_BASE']}"
        )
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_image(tag, file, username = ENV['USER'], additional_build_arg='')
      system("docker build -t #{tag} -f #{file} --build-arg username=#{username} #{additional_build_arg} .")
    end
  end
end
