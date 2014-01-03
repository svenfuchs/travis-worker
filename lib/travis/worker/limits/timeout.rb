require 'core_ext/string/strip_lines'

module Travis
  class Worker
    class Limits
      class Timeout < Struct.new(:reporter, :config)
        ERROR_MSG = <<-msg.strip_lines
          Execution expired after %d minutes.
        msg

        def initialize(*)
          super
          @started = Time.now
        end

        def exceeded?
          @started + config[:timeout] < Time.now
        end

        def error_msg
          ERROR_MSG % (config[:timeout] / 60)
        end
      end
    end
  end
end
