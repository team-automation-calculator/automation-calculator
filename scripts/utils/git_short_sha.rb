class GitShortSha
  class << self
    def read
      sha = `git rev-parse --short HEAD 2>/dev/null`.strip
      sha.empty? ? 'unknown' : sha
    end
  end
end
