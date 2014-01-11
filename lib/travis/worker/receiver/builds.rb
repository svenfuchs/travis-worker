require 'core_ext/class/attr_initializer'
require 'core_ext/string/camelize'
require 'travis/worker/receiver/consumer/amqp'
require 'travis/worker/receiver/consumer/stub'
require 'travis/worker/runner'

module Travis
  class Worker
    class Receiver
      class Builds
        def self.create(num, config)
          consumer = Consumer.const_get("#{config[:receiver][:builds]}::Builds".camelize).new(config)
          runner = Runner.create(num, config)
          new(num, config, consumer, runner)
        end

        attr_initializer :num, :config, :consumer, :runner

        def start
          consumer.subscribe(&method(:receive))
          # puts "[#{num}] Subscribed."
        end

        def receive(payload)
          runner.run(normalize(payload))
        end

        def unsubscribe
          consumer.unsubscribe
        end

        def busy?
          runner.running?
        end

        def cancel_job(payload)
          runner.cancel if runner && runner.runs_job?(payload[:job_id])
        end

        private

          def normalize(payload)
            payload[:lang] ||= 'ruby'
            payload[:image] ||= "travis:#{payload[:lang]}"
            payload
          end
      end
    end
  end
end
