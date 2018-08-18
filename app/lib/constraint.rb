class Constraint
  attr_reader :version

  def initialize(version)
    @version = version.to_s
  end

  def matches?(request)
    accept_header = request.headers['Accept']
    if accept_header
      accept_header[%r{application/json; version=(\d+)}, 1] == version
    else
      false
    end
  end
end
