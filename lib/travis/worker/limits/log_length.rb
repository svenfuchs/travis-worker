require 'core_ext/string/strip_lines'

module Travis
  class Worker
    class Limits
      class LogLength < Struct.new(:reporter, :config)
        ERROR_MSG = <<-msg.strip_lines
          The log length has exceeded the limit of %d MB.
          Hint: this often means the same exception was raised over and over.
        msg

        def exceeded?
          reporter.log_length > config[:log_length]
        end

        def error_msg
          ERROR_MSG % (config[:log_length] / (1024 * 1024))
        end
      end
    end
  end
end
