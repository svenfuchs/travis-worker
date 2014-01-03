require 'core_ext/string/camelize'
require 'travis/worker/reporter/adapter/amqp'
require 'travis/worker/reporter/adapter/log'
require 'travis/worker/reporter/adapter/memory'

module Travis
  class Worker
    class Reporter
      class Dispatch
        def initialize(config)
          @publishers = [:state, :log].inject({}) do |publishers, type|
            publishers.merge(type => create_publishers(type, config))
          end
        end

        def publish(type, *args)
          @publishers[type].each { |publisher| publisher.send(type, *args) } if @publishers[type]
        end

        private

          def create_publishers(type, config)
            Array(config[:reporter][type]).map do |type|
              Adapter.const_get(type.to_s.camelize).new(config)
            end
          end
      end
    end
  end
end
