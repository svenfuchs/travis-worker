require 'core_ext/string/camelize'
require 'travis/worker/receiver/consumer/amqp'
require 'travis/worker/receiver/consumer/stub'

module Travis
  class Worker
    class Receiver
      class Commands
        def self.create(num, config, listeners)
          consumer = Consumer.const_get("#{config[:receiver][:commands]}::Commands".camelize).new(config)
          new(num, consumer, listeners)
        end

        attr_initializer :num, :consumer, :listeners
        attr_reader :command

        def start
          consumer.subscribe(&method(:receive))
          # puts "[#{num}] Subscribed."
        end

        def receive(payload)
          case @command = payload[:type].to_s
          when 'cancel_job'
            notify(@command, payload)
          else
            raise "Unknown command: #{command.inspect}"
          end
          @command = nil
        end

        def unsubscribe
          consumer.unsubscribe
        end

        def busy?
          !!command
        end

        private

          def notify(command, payload)
            listeners.each do |subscriber|
              subscriber.send(command, payload) if subscriber.respond_to?(command)
            end
          end
      end
    end
  end
end

