require 'multi_json'
require 'travis/worker/utils/amqp'
require 'travis/worker/utils/logging'

MultiJson.engine = :ok_json

module Travis
  class Worker
    class Reporter
      module Publisher
        class Amqp
          class Exchange
            include Logging

            attr_reader :routing_key, :exchange

            def initialize(routing_key)
              @routing_key = routing_key
              channel = Worker::Amqp.create_channel
              @exchange = channel.exchange('reporting', type: :topic, durable: true)
              channel.queue(routing_key, durable: true).bind('reporting', routing_key: routing_key)
            end

            def publish(event, payload)
              channel_closed(event, payload) && return unless exchange.channel.open?
              payload = MultiJson.encode(payload)
              options = { properties: { type: event }, routing_key: routing_key }
              @exchange.publish(payload, options)
            end

            def channel_closed(event, payload)
              # logger.error("trying to publish to a closed channel for #{event.inspect}: #{payload}")
            end
          end

          def initialize(config)
            config[:amqp] ||= {}
            @states = Exchange.new(config[:amqp][:state_routing_key] || 'reporting.jobs.builds')
            @logs   = Exchange.new(config[:amqp][:logs_routing_key]  || 'reporting.jobs.logs')
          end

          def state(num, event, payload)
            @states.publish(event, payload) unless event == 'job:test:boot' # not implemented, but might be interesting
          end

          def log(num, event, payload)
            @logs.publish('job:test:log', payload)
          end
        end
      end
    end
  end
end
