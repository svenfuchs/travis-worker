require 'core_ext/string/strip_lines'

module Travis
  class Worker
    class RubyLandError < StandardError
      attr_reader :result

      def initialize(error)
        @error = error
        @result = :errored
        super("#{error.message}\n#{error.backtrace.join("\n")}")
      end
    end

    class WorkerError < StandardError
      attr_reader :result
    end

    class RestartableError < WorkerError
      def initialize(msg)
        @result = :reset
        super("#{msg}\nThis build will be restarted.")
      end
    end

    class FatalError < WorkerError
      def initialize(msg)
        @result = :errored
        super
        super("#{msg}\nThis build has been terminated.")
      end
    end

    class BuildError < RestartableError
    end

    class LimitExceededError < FatalError
    end

    class CompileError < FatalError
      def initialize(exception)
        msg = %(
          An error occured while compiling the build script:
          #{exception.message}
          #{exception.backtrace}
        )
        super(msg.strip_lines)
      end
    end

    class ConfigParseError < FatalError
      def initialize
        msg = %(
          An error occured while trying to parse your .travis.yml file.
          Please make sure that the file is valid YAML.
        )
        super(msg.strip_lines)
      end
    end
  end
end
