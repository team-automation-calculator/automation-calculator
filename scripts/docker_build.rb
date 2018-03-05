class DockerBuild
  class << self
    def build(cmds)
      sub_cmd = cmds.shift || 'dev'

      case sub_cmd
      when 'dev'
        build_image('automationcalculator_dev:latest', 'Dockerfile.development')
      when 'ci'
        tag = "#{ENV['SEMVER_MAJOR_VERSION']}.#{ENV['SEMVER_MINOR_VERSION']}.#{ENV['SEMVER_PATCH']}-#{ENV['CIRCLE_BUILD_NUM']}"
        repo = 'automationcalculator/automation-calculator-rails'
        image = "#{repo}:#{tag}"
        build_image(image, 'Dockerfile.ci')
        system("docker tag #{image} #{repo}:latest")
      when 'base'
        build_image('automationcalculators/automation-calculator-base:0.0.2', 'Dockerfile.base', 'circleci')
      else
        warn "Unrecognized command: #{sub_cmd}"
      end
    end

    def build_image(tag, file, username = ENV['USER'])
      system("docker build -t #{tag} -f #{file} --build-arg username=#{username}  .")
    end
  end
end
