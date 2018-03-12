class DockerHub
  REPO = 'automationcalculator/automation-calculator-rails'.freeze

  class << self
    def semver_tag
      "#{ENV['SEMVER_MAJOR_VERSION']}."\
      "#{ENV['SEMVER_MINOR_VERSION']}."\
      "#{ENV['SEMVER_PATCH']}-"\
      "#{ENV['CIRCLE_BUILD_NUM']}"
    end

    def image_with_semver
      "#{REPO}:#{semver_tag}"
    end

    def tag_latest_with_semver
      system("docker tag #{latest_tag} #{image_with_semver}")
    end

    def latest_tag
      "#{REPO}:latest"
    end

    def push_to_docker_hub
      [semver_tag, latest_tag].each { |tag| system("docker push #{tag}") }
    end
  end
end
