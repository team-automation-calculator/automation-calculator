# Commands to view logs
class Logs
  class << self
    def logs
      system('docker compose logs --follow dev')
    end
  end
end
