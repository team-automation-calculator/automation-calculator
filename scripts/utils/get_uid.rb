class GetUID
  class << self
    def read_uid
      `id -u`.strip
    end
  end
end
