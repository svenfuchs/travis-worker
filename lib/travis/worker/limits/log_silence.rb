require 'core_ext/class/attr_initializer'
require 'core_ext/string/strip_lines'

module Travis
  class Worker
    class Limits
      class LogSilence
        ERROR_MSG = <<-msg.strip_lines
          No output has been received in the last %d minutes. This indicates a stalled build.
        msg

        attr_initializer :reporter, :config

        def exceeded?
          reporter.last_logged_at + config[:log_silence] <= Time.now
        end

        def error_msg
          ERROR_MSG % (config[:log_silence] / 60)
        end
      end
    end
  end
end
