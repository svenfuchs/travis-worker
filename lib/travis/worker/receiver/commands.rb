require 'core_ext/string/camelize'
require 'travis/worker/receiver/adapter/amqp'

module Travis
  class Worker
    class Receiver
      class Commands
        def self.create(num, config)
          adapter = Adapter.const_get("#{config[:receiver][:commands]}::Commands".camelize)
          consumer = adapter.new(config[:amqp][:connection], config[:amqp][:commands_queue])
          new(num, consumer)
        end

        attr_reader :num, :consumer, :subscribers

        def initialize(num, consumer)
          @num = num
          @consumer = consumer
          @subscribers = []
          puts "[#{num}] Subscribing to: #{consumer.name}"
          consumer.subscribe(&method(:receive))
        end

        def receive(payload)
          case @command = payload[:type].to_s
          when 'cancel_job'
            run @command, job_id: payload[:job_id]
          else
            raise("Unknown command: #{command.inspect}")
          end
          @command = nil
        end

        def unsubscribe
          consumer.unsubscribe
        end

        def busy?
          !!@command
        end

        private

          def run(command, payload)
            subscribers.each do |subscriber|
              subscriber.send(command, payload) if subscriber.respond_to?(command)
            end
          end
      end
    end
  end
end

