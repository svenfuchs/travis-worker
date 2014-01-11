require 'base64'
require 'shellwords'
require 'travis/worker/exceptions'
require 'travis/worker/utils/logging'
require 'travis/worker/utils/popen'

module Travis
  class Worker
    class Runner
      class Docker < Runner
        include Popen, Logging

        attr_reader :cid

        def self.cleanup_periodically(config)
          run_periodically(config[:cleanup][:interval] || 5, rescue: true) do
            Popen.popen(Command::Docker.new(config).cleanup)
          end
        end

        private

          def execute
            super
            process = popen(command.build(payload))
            @cid = process.stdout.read(12)
            read(process.stdout)
            raise_errors(process.stderr)
            process.wait
            @cid = nil
            process.exit_status
          end

          def halt
            return unless cid
            process = popen(command.halt(cid))
            log_errors(process.stderr)
            process.wait
          end

          def read(io)
            reporter.log io.readpartial(1024) until canceled? || io.closed?
          rescue EOFError
          end

          def raise_errors(io)
            errors = log_errors(io)
            raise BuildError, errors if errors
          end

          def log_errors(io)
            errors = io.read
            return if errors.empty?
            logger.error("Error: #{errors}")
            errors
          end
      end
    end
  end
end
