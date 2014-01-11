require 'core_ext/class/attr_initializer'
require 'core_ext/string/strip_lines'
require 'travis/worker/exceptions'

module Travis
  class Worker
    class Runner
      class Config
        NOT_FOUND_MSG = <<-msg.strip_lines
          We were unable to find a .travis.yml file. This may not be what you want.
          The build will be run with default settings.
        msg

        attr_initializer :reporter

        def check(payload)
          config = payload[:config] || {}
          case config[:'.result']
          when 'parse_error'
            raise ConfigParseError
          when 'not_found'
            reporter.on_warning NOT_FOUND_MSG
          end
        end
      end
    end
  end
end
