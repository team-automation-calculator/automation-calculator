class DockerHub
  REPO='automationcalculator/automation-calculator-rails'.freeze

  class << self
    def docker_image_tag
      "#{ENV['SEMVER_MAJOR_VERSION']}."\
      "#{ENV['SEMVER_MINOR_VERSION']}."\
      "#{ENV['SEMVER_PATCH']}-"\
      "#{ENV['CIRCLE_BUILD_NUM']}"
    end

    def image_with_semver
      "#{REPO}:#{docker_image_tag}"
    end

    def tag_latest_with_semver
      system("docker tag #{REPO}:latest #{image_with_semver}")
    end

    def push_to_docker_hub
      system("docker push #{REPO}:#{docker_image_tag}")
    end
  end
end