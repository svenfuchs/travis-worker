require 'spec_helper'
require 'travis/worker/receiver/commands'

describe Travis::Worker::Receiver::Commands do
  let(:config)   { { receiver: { commands: :stub } } }
  let(:runner)   { double('runner') }
  let(:consumer) { double('consumer', subscribe: true) }
  let(:listener) { double('listener') }
  let(:receiver) { described_class.new(0, consumer, [listener]) }

  describe '.create' do
    it 'instantiates the consumer given by the :receiver config' do
      allow(Travis::Worker::Runner).to receive(:create).and_return(runner)
      receiver = described_class.create(0, config, [])
      expect(receiver.consumer).to be_instance_of(Travis::Worker::Receiver::Consumer::Stub::Commands)
    end
  end

  describe 'receive' do
    it 'notifies listeners about :cancel_job' do
      payload = { type: :cancel_job, job_id: 1 }
      expect(listener).to receive(:cancel_job).with(payload)
      receiver.receive(payload)
    end

    it 'raises on unknown commands' do
      payload = { type: :unknown }
      expect { receiver.receive(payload) }.to raise_error
    end
  end

  it 'unsubscribe unsubscribes the consumer' do
    expect(consumer).to receive(:unsubscribe)
    receiver.unsubscribe
  end

  describe 'busy?' do
    it 'busy? returns true if receiver has a current command' do
      expect(receiver).to receive(:command).and_return('command')
      receiver.busy?
    end

    it 'busy? returns true if receiver runs a command' do
      done = false
      allow(receiver).to receive(:notify).and_return { sleep 0.001 until done }
      Thread.new { receiver.receive(type: :cancel_job) }
      sleep 0.01
      expect(receiver.busy?).to be_true
      done = true
    end

    it 'busy? returns false if receiver does not run a command' do
      done = false
      allow(receiver).to receive(:notify).and_return { sleep 0.001 until done }
      Thread.new { receiver.receive(type: :cancel_job) }
      done = true
      sleep 0.01
      expect(receiver.busy?).to be_false
    end
  end
end

