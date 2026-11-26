require 'set'

module RuboCop
  module Cop
    module Scripts
      # Only Runner (scripts/utils/runner.rb) reaches the shell. A ./go
      # command takes its runner in the initializer, so a spec passes a
      # recorder instead (the dependency inversion of the solid rule).
      # Loaded by scripts/.rubocop.yml.
      #
      # @example
      #   # bad
      #   system("docker compose up")
      #   `git rev-parse HEAD`
      #   Open3.capture3('git', 'status')
      #
      #   # good
      #   @runner.run('docker compose up')
      class ShellBoundary < Base
        MSG = 'Reach the shell through the Runner passed in (scripts/utils/runner.rb), so a spec can record it.'.freeze
        SHELL_METHODS = %i[system exec spawn ` popen capture2 capture2e capture3 popen2 popen3 pipeline].freeze
        RESTRICT_ON_SEND = SHELL_METHODS
        SHELL_RECEIVERS = Set[nil, :Kernel, :Open3, :Process, :IO].freeze

        def on_send(node)
          add_offense(node) if SHELL_RECEIVERS.include?(receiver_name(node.receiver))
        end

        def on_xstr(node)
          add_offense(node)
        end

        private

        # nil for a bare call; the constant's name for Kernel.system and the
        # like; a sentinel for any other receiver (@runner.run is fine).
        def receiver_name(receiver)
          return if receiver.nil?

          receiver.const_type? && receiver.namespace.nil? ? receiver.short_name : :other
        end
      end
    end
  end
end
