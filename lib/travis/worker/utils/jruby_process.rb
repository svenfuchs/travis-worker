module Travis
  class Worker
    class JRubyProcess
      SIGNALS = { hub: 1, int: 2, quit: 3, kill: 9, term: 15 }

      attr_reader :builder, :process

      def initialize(cmd)
        @builder = Java::JavaLang::ProcessBuilder.new('bash', '-c', cmd)
      end

      def start
        @process = builder.start
      end

      def stdout
        @stdout ||= process.input_stream.to_io
      end

      def stdin
        @stdin ||= process.output_stream.to_io
      end

      def stderr
        @stderr ||= process.error_stream.to_io
      end

      def wait
        process.waitFor
      end

      def exit_status
        process.exitValue
      end

      def pid
        @pid ||= Java::OrgJrubyUtil::ShellLauncher.getPidFromProcess(@process)
      end

      def signal(signal)
        signal = SIGNALS[signal] || raise("Unknown signal: #{signal.inspect}")
        process.kill(signal)
      end

      def method_missing(name, *args, &block)
        name =~ /^signal_(.*)$/ ? signal($1) : super
      end
    end
  end
end
