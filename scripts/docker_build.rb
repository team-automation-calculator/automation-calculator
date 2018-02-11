class DockerBuild
  class << self
    def build(cmds)
      sub_cmd = cmds.shift || 'dev'

      case sub_cmd
      when 'dev'
        build_image('automationcalculator_dev:latest', 'Dockerfile.development')
      when 'ci'
        build_image('automationcalculator_ci:latest', 'Dockerfile.ci')
      when 'base'
        build_image('automationcalculators/automation-calculator-base:0.0.2', 'Dockerfile.base', 'circleci')
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_image(tag, file, username = ENV['USER'])
      exec("docker build -t #{tag} -f #{file} --build-arg username=#{username}  .")
    end
  end
end
