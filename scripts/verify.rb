class Verify
  class << self
    def rspec_test(cmds)
      env = cmds.shift || 'dev'
      case env
      when 'dev'
        exec('docker-compose -f docker-compose.yml -f docker-compose.dev.yml run -e RAILS_ENV=test --rm dev rspec')
      when 'ci'
        exec('RAILS_ENV=test docker-compose -f docker-compose.yml -f docker-compose.ci.yml run --rm ci')
      else
        warn "Unrecognized command: #{env}"
      end
    end

    def lint(cmds)
      env = cmds.shift.to_s

      if env == 'ci'
        exec('docker-compose -f docker-compose.yml -f docker-compose.ci.yml run --no-deps --rm ci rubocop')
      else
        exec('docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --no-deps --rm dev rubocop')
      end
    end
  end
end
