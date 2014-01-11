begin
  require 'march_hare'
rescue LoadError
end
require 'multi_json'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/worker/utils/amqp'

module AmqpHelpers
  def amqp
    @amqp ||= Amqp.new
  end

  class Amqp
    class Publisher
      def initialize(connection, routing_key, type)
        channel = connection.create_channel
        @exchange = channel.exchange('', type: type, durable: true)
        @routing_key = routing_key
      end

      def publish(payload)
        @exchange.publish(MultiJson.encode(payload), routing_key: @routing_key)
      end
    end

    class Consumer
      def initialize(connection, routing_key)
        channel = connection.create_channel
        channel.prefetch = 100
        @queue = channel.queue(routing_key, durable: true).bind('reporting', routing_key: routing_key)
      end

      def receive
        1.upto(@queue.message_count).map do
          message, payload = @queue.pop
          event = message.properties.type
          payload = MultiJson.decode(payload).deep_symbolize_keys
          [event, payload]
        end
      end

      def purge
        @queue.purge
      end
    end

    def connection
      Travis::Worker::Amqp.connection
    end

    def purge
      states.purge
      logs.purge
    end

    def builds
      @builds ||= Publisher.new(connection, 'builds', 'direct')
    end

    def commands
      @commands ||= Publisher.new(connection, 'worker.commands', 'fanout')
    end

    def states
      @states ||= Consumer.new(connection, 'reporting.jobs.builds')
    end

    def logs
      @logs ||= Consumer.new(connection, 'reporting.jobs.logs')
    end
  end
end
