require 'core_ext/class/attr_initializer'
require 'core_ext/string/strip_lines'

module Travis
  class Worker
    class Limits
      class Timeout
        ERROR_MSG = <<-msg.strip_lines
          Execution expired after %d minutes.
        msg

        attr_initializer :reporter, :config

        def exceeded?
          reporter.started_at + config[:timeout] <= Time.now
        end

        def error_msg
          ERROR_MSG % (config[:timeout] / 60)
        end
      end
    end
  end
end
