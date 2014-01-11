begin
  require 'march_hare'
rescue LoadError
end

require 'multi_json'
require 'core_ext/class/attr_initializer'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/worker/utils/amqp'

MultiJson.engine = :ok_json

module Travis
  class Worker
    class Receiver
      module Consumer
        class Amqp
          class Queue
            attr_initializer :config

            def subscribe(&block)
              @callback = block
              @consumer = @queue.subscribe(ack: true, blocking: false, &method(:receive))
            end

            def unsubscribe
              @consumer.cancel
            end

            def receive(message, payload)
              payload = normalize(payload)
              @callback.call(payload)
            rescue => e
              puts e.message, e.backtrace
            ensure
              message.ack if @queue.channel.open?
            end

            def normalize(payload)
               MultiJson.decode(payload).deep_symbolize_keys
            end
          end

          class Builds < Queue
            def initialize(*)
              super
              config[:amqp] ||= {}
              channel = Worker::Amqp.create_channel(prefetch: 1)
              @queue = channel.queue(config[:amqp][:builds_queue] || 'builds', durable: true)
            end
          end

          class Commands < Queue
            def initialize(*)
              super
              config[:amqp] ||= {}
              channel = Worker::Amqp.create_channel(prefetch: 1)
              exchange = channel.fanout(config[:amqp][:commands_queue] || 'worker.commands')
              @queue = channel.queue('') # TODO exclusive: true?
              @queue.bind(exchange)
            end
          end
        end
      end
    end
  end
end
