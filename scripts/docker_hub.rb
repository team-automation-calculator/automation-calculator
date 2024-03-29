# Interract with the DockerHub
class DockerHub
  REPO = 'automationcalculationsci/automation-calculator'.freeze

  class << self
    def semver_tag
      "#{ENV['SEMVER_MAJOR_VERSION']}."\
      "#{ENV['SEMVER_MINOR_VERSION']}."\
      "#{ENV['SEMVER_PATCH']}-"\
      "#{ENV['CIRCLE_BUILD_NUM']}"
    end

    def image_w_semver
      "#{REPO}:#{semver_tag}"
    end

    def tag_latest_with_semver
      system("docker tag #{latest_tag} #{image_w_semver}")
    end

    def latest_tag
      "#{REPO}:latest"
    end

    def push_to_docker_hub
      [image_w_semver, latest_tag].each { |tag| system("docker push #{tag}") }
    end
  end
end
