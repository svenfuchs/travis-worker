require 'timeout'

module AsyncRunHelpers
  def run(payload)
    raise 'Define `run` according to your test setup'
  end

  def while_running(start)
    runner = respond_to?(:runner) ? self.runner : begin
      builds = worker.receivers.detect { |receiver| receiver.class.name.include?('Builds') }
      runner = builds.runner
    end

    done = false
    allow(runner).to receive(:execute).and_return { sleep 0.005 until done }

    Thread.new do
      begin
        run(payload)
      rescue => e
        puts e.message, e.backtrace
      end
    end
    sleep 0.001 until runner.running?

    yield
    done = true
    sleep 0.001 while runner.running?
  end

  def wait_for_build_finished
    builds = worker.receivers.detect { |receiver| receiver.class.name.include?('Builds') }
    publishers = builds.runner.reporter.dispatcher.publishers[:state]
    publisher = publishers.detect { |publisher| publisher.class.name.include?('Memory') }
    raise('wait_for_build_finished needs a memory publisher hooked up') unless publisher
    data = publisher.data

    Timeout.timeout(1) do
      sleep 0.1 until (data.last || []).first == 'job:test:finish'
    end
  end
end
