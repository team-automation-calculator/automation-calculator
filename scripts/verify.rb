class Verify
  class << self
    def rspec_test(cmds)
      env = cmds.shift || 'dev'
      case env
      when 'dev'
        exec('docker-compose run dev rspec')
      when 'ci'
        exec('docker-compose -f docker-compose.yml -f docker-compose.ci.yml run ci')
      else
        warn "Unrecognized command: #{env}"
      end
    end

    def lint(cmds)
      env = cmds.shift.to_s

      if env == 'ci'
        exec('docker-compose -f docker-compose.yml -f docker-compose.ci.yml run ci rubocop')
      else
        exec('docker-compose run dev rubocop')
      end
    end
  end
end
