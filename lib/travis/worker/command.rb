begin
  require 'travis/build'
rescue LoadError
end
require 'core_ext/class/attr_initializer'

module Travis
  module Command
    class Build
      attr_initializer :config

      def cmd(payload)
        config[:command] || compile(payload)
      end

      private

        def compile(payload)
          data = payload.merge(timeouts: false, hosts: config[:hosts], cache_options: config[:cache_options])
          Travis::Build.script(data, logs: { build: false, state: true }).compile
        rescue => e
          raise CompileError, e
        end
    end

    class Stub
      attr_initializer :config

      def build(payload)
        config[:command]
      end
    end

    class Docker
      attr_initializer :config

      def build(payload)
        cmd = Build.new(config).cmd(payload)
        cmd = "echo $HOSTNAME; echo #{Base64.strict_encode64(cmd)} | base64 -d | bash 2>&1"
        cmd = "sudo docker run #{payload[:image]} bash -c #{Shellwords.escape(cmd)}"
        cmd = prefix_ssh(cmd)
        cmd
      end

      def halt(cid)
        prefix_ssh "sudo docker ps -q | grep #{cid} && sudo docker kill #{cid}"
      end

      def cleanup
        prefix_ssh "ids=$(sudo docker ps -a -q); [ -z \"$ids\" ] || sudo docker rm $ids"
      end

      private

        def prefix_ssh(cmd)
          config[:ssh] ? "ssh #{ssh_host} #{ssh_opts} #{Shellwords.escape(cmd)}" : cmd
        end

        def ssh_host
          "#{config[:ssh][:user]}@#{config[:ssh][:host]}"
        end

        def ssh_opts
          '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error'
        end
    end
  end
end
