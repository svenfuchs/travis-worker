require 'core_ext/string/camelize'
require 'travis/worker/reporter/publisher/amqp'
require 'travis/worker/reporter/publisher/log'
require 'travis/worker/reporter/publisher/memory'

module Travis
  class Worker
    class Reporter
      class Dispatcher
        attr_reader :publishers

        def initialize(config)
          @publishers = [:state, :log].inject({}) do |publishers, type|
            publishers.merge(type => create_publishers(type, config))
          end
        end

        %i(state log).each do |type|
          define_method(type) { |*args| publish(type, *args) }
        end

        private

          def publish(type, *args)
            publishers[type].each { |publisher| publisher.send(type, *args) } if publishers[type]
          end

          def create_publishers(type, config)
            Array(config[:reporter][type]).map do |type|
              Publisher.const_get(type.to_s.camelize).new(config)
            end
          end
      end
    end
  end
end
