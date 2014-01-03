require 'base64'
require 'shellwords'
require 'travis/worker/exceptions'
require 'travis/worker/utils/logging'
require 'travis/worker/utils/popen'

module Travis
  class Worker
    class Runner
      class Docker < Runner
        extend Popen
        include Popen, Logging

        def self.prefix_command(config, cmd)
          cmd = "ssh #{config[:ssh][:username]}@#{config[:ssh][:host]} #{Shellwords.escape(cmd)}" if config[:ssh]
          cmd
        end

        def self.cleanup_periodically(config)
          run_periodically(config[:cleanup][:interval] || 5) do
            cmd = "ids=$(sudo docker ps -a -q); [ -z \"$ids\" ] || sudo docker rm $ids"
            process = popen(prefix_command(config, cmd))
          end
        end

        private

          def execute
            return if canceled?
            process = popen(prefix_command(cmd))
            @cid = process.stdout.read(12)
            read(process.stdout) { |log| reporter.log(log) }
            handle_errors(process.stderr)
            process.wait
            @cid = nil
          end

          def halt
            return unless @cid
            process = popen(prefix_command("sudo docker ps -q | grep #{@cid} && sudo docker kill #{@cid}"))
            handle_errors(process.stderr)
            process.wait
          end

          def cmd
            cmd = Base64.strict_encode64(super)
            cmd = "bash -c 'echo $HOSTNAME; echo #{cmd} | base64 -d | bash 2>&1'"
            cmd = "sudo docker run #{image} #{cmd}"
            cmd
          end

          def prefix_command(cmd)
            self.class.prefix_command(config, cmd)
          end

          def image
            payload[:image] || payload[:lang] || 'travis:ruby'
          end

          def read(io)
            yield io.readpartial(1024) until canceled? || io.closed?
          rescue EOFError
          end

          def handle_errors(io)
            error = io.read
            return if error.empty?
            logger.error("Error: #{error}")
            raise BuildError, error
          end
      end
    end
  end
end
