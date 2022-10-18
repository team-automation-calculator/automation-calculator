class GetUID
  class << self
    def get_uid
      return `id -u`.strip
    end
  end
end

