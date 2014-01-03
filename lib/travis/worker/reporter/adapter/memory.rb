module Travis
  class Worker
    class Reporter
      module Adapter
        class Memory
          attr_reader :data

          def intialize(*)
            @data = []
          end

          def state(num, event, payload)
            data << [num, event, payload]
          end

          def log(num, payload)
            data << [num, :log, payload]
          end
        end
      end
    end
  end
end
