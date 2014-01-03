require 'multi_json'
require 'travis/worker/utils/amqp'
require 'travis/worker/utils/logging'

MultiJson.engine = :ok_json

module Travis
  class Worker
    class Reporter
      module Adapter
        class Amqp
          class Exchange < Struct.new(:routing_key)
            include Logging

            attr_reader :exchange

            def initialize(*)
              super
              channel = Worker::Amqp.create_channel
              channel.queue(routing_key, durable: true).bind('reporting', routing_key: routing_key)
              @exchange = channel.exchange('reporting', type: :topic, durable: true)
            end

            def publish(event, payload)
              channel_closed(event, payload) && return unless exchange.channel.open?
              payload = MultiJson.encode(payload)
              options = { properties: { type: event }, routing_key: routing_key }
              @exchange.publish(payload, options)
            end

            def channel_closed(event, payload)
              logger.error("trying to publish to a closed channel for #{event.inspect}: #{payload}")
            end
          end

          def initialize(config)
            @states = Exchange.new(config[:amqp][:state_routing_key])
            @logs   = Exchange.new(config[:amqp][:logs_routing_key])
          end

          def state(num, event, payload)
            @states.publish(event, payload)
          end

          def log(num, payload)
            @logs.publish('job:test:log', payload)
          end
        end
      end
    end
  end
end
