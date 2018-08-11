class ClearRailsPid
  PID_PATH='./tmp/pids/server.pid'

  class << self
    def clear_pid_file_if_it_exists
      if FileTest.exist? PID_PATH
        File.delete(PID_PATH)
      end
    end
  end
end
