require 'core_ext/class/attr_initializer'

module Travis
  class Worker
    class Receiver
      module Consumer
        class Stub
          class Queue
            attr_initializer :config

            def subscribe(&block)
            end

            def unsubscribe
            end

            def receive(message, payload)
            end

            def normalize(payload)
            end
          end

          class Builds < Queue
            def name
            end
          end

          class Commands < Queue
            def name
            end
          end
        end
      end
    end
  end
end

