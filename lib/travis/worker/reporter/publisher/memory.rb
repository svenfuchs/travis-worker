module Travis
  class Worker
    class Reporter
      module Publisher
        class Memory
          attr_reader :data

          def initialize(*)
            @data = []
          end

          def state(num, event, payload)
            data << [event, payload] unless event == 'job:test:boot' # not implemented, but might be interesting
          end

          def log(num, event, payload)
            data << [event, payload]
          end
        end
      end
    end
  end
end
