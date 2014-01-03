module Travis
  class Worker
    class Reporter
      module Adapter
        class Log
          def initialize(*)
          end

          def state(num, event, payload)
            puts "[worker-#{num}][job-#{payload[:id]}] #{event}: #{payload}"
          end

          def log(num, payload)
            log = payload[:final] ? '[final]' : payload[:log]
            log.split("\n").each do |line|
              puts "[worker-#{num}][job-#{payload[:id]}][part-#{payload[:number]}] log: #{line}"
            end
          end
        end
      end
    end
  end
end
