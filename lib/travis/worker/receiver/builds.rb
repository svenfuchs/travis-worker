require 'core_ext/string/camelize'
require 'travis/worker/receiver/adapter/amqp'
require 'travis/worker/runner'

module Travis
  class Worker
    class Receiver
      class Builds
        def self.create(num, config)
          adapter = Adapter.const_get("#{config[:receiver][:builds]}::Builds".camelize)
          consumer = adapter.new(config[:amqp][:connection], config[:amqp][:builds_queue])
          runner = Runner.create(num, config)
          new(num, config, consumer, runner)
        end

        attr_reader :num, :config, :consumer, :runner

        def initialize(num, config, consumer, runner)
          @num = num
          @config = config
          @consumer = consumer
          @runner = runner
          puts "[#{num}] Subscribing to: #{consumer.name}"
          consumer.subscribe(&method(:receive))
        end

        def receive(payload)
          runner.run(payload)
        end

        def unsubscribe
          consumer.unsubscribe
        end

        def busy?
          runner.busy?
        end

        def cancel_job(payload)
          runner.cancel if runner && runner.runs_job?(payload[:job_id])
        end
      end
    end
  end
end
