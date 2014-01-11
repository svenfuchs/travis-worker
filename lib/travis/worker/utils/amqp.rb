require 'forwardable'

module Travis
  class Worker
    class Amqp
      class << self
        attr_reader :config, :connection, :logs_channel, :states_channel

        def connect(config = {})
          @config = config
        end

        def connection
          unless @connection
            @connection = MarchHare.connect(config || {})
            @logs_channel = create_channel
            @states_channel = create_channel
          end
          @connection
        end

        def disconnect
          connection.close
          @connection = nil
        end

        def create_channel(options = {})
          channel = connection.create_channel
          channel.prefetch = options[:prefetch] if options[:prefetch]
          channel
        end
      end
    end
  end
end
