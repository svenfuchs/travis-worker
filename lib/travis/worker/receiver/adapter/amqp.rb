require 'march_hare'
require 'multi_json'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/worker/utils/amqp'

MultiJson.engine = :ok_json

module Travis
  class Worker
    class Receiver
      module Adapter
        class Amqp
          class Queue < Struct.new(:connection, :name)
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
              channel = Worker::Amqp.create_channel(prefetch: 1)
              @queue = channel.queue(name, durable: true)
            end
          end

          class Commands < Queue
            def initialize(*)
              super
              channel = Worker::Amqp.create_channel(prefetch: 1)
              exchange = channel.fanout(name)
              @queue = channel.queue('') # TODO exclusive: true?
              @queue.bind(exchange)
            end
          end
        end
      end
    end
  end
end
