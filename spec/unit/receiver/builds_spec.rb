require 'spec_helper'
require 'travis/worker/receiver/builds'

describe Travis::Worker::Receiver::Builds do
  let(:config)   { { receiver: { builds: :stub } } }
  let(:runner)   { double('runner') }
  let(:consumer) { double('consumer', subscribe: true) }
  let(:receiver) { described_class.new(0, config, consumer, runner) }

  describe '.create' do
    it 'instantiates the consumer given by the :receiver config' do
      allow(Travis::Worker::Runner).to receive(:create).and_return(runner)
      receiver = described_class.create(0, config)
      expect(receiver.consumer).to be_instance_of(Travis::Worker::Receiver::Consumer::Stub::Builds)
    end
  end

  it 'receive starts the runner with the given payload' do
    payload = { job: { id: 1 } }
    expect(runner).to receive(:run).with(payload)
    receiver.receive(payload)
  end

  it 'unsubscribe unsubscribes the consumer' do
    expect(consumer).to receive(:unsubscribe)
    receiver.unsubscribe
  end

  it 'busy? returns true if the runner is running' do
    expect(runner).to receive(:running?).and_return(true)
    receiver.busy?
  end

  describe 'cancel_job' do
    let(:payload) { { job_id: 1 } }

    it 'cancels the runner if the runner runs the given job' do
      expect(runner).to receive(:runs_job?).with(1).and_return true
      expect(runner).to receive(:cancel)
      receiver.cancel_job(payload)
    end

    it 'does not cancel the runner if the runner does not run the given job' do
      expect(runner).to receive(:runs_job?).with(1).and_return false
      expect(runner).to_not receive(:cancel)
      receiver.cancel_job(payload)
    end
  end
end
