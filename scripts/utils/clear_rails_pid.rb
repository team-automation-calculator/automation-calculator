class ClearRailsPid
  PID_PATH = './tmp/pids/server.pid'.freeze

  class << self
    def clear_pid_file_if_it_exists
      File.delete(PID_PATH) if FileTest.exist? PID_PATH
    end
  end
end
