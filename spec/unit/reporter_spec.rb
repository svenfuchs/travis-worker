require 'spec_helper'
require 'travis/worker/reporter'

describe Travis::Worker::Reporter do
  include StubTime

  let(:config)     { { logs: { buffer: 0 }, reporter: { logs: :memory, state: :memory } } }
  let(:publishers) { Travis::Worker::Reporter::Dispatcher.new(config) }
  let(:reporter)   { Travis::Worker::Reporter.new(0, config, publishers) }

  before :each do
    reporter.start(1)
  end

  describe 'start' do
    it 'resets the reporter' do
      expect(reporter).to receive(:reset)
      reporter.start(1)
    end

    it 'starts the buffer' do
      expect(reporter.buffer).to receive(:start)
      reporter.start(1)
    end
  end

  describe 'on_boot' do
    it 'publishes "job:test:boot"' do
      expect(publishers).to receive(:state).with(0, 'job:test:boot', id: 1, state: 'booted', booted_at: now.utc.to_s)
      reporter.on_boot
    end
  end

  describe 'on_start' do
    it 'publishes "job:test:start"' do
      expect(publishers).to receive(:state).with(0, 'job:test:start', id: 1, state: 'started', started_at: now.utc.to_s)
      reporter.on_start
    end
  end

  describe 'on_finish' do
    it 'publishes "job:test:finish" with state "passed" if result is 0' do
      expect(publishers).to receive(:state).with(0, 'job:test:finish', id: 1, state: 'passed', finished_at: now.utc.to_s)
      reporter.on_finish(0)
    end

    it 'publishes "job:test:finish" with state "failed" if result is 1' do
      expect(publishers).to receive(:state).with(0, 'job:test:finish', id: 1, state: 'failed', finished_at: now.utc.to_s)
      reporter.on_finish(1)
    end

    it 'publishes "job:test:finish" with state "canceled" if result is :canceled' do
      expect(publishers).to receive(:state).with(0, 'job:test:finish', id: 1, state: 'canceled', finished_at: now.utc.to_s)
      reporter.on_finish(:canceled)
    end

    it 'publishes "job:test:reset" with state "reset" if result is :reset' do
      expect(publishers).to receive(:state).with(0, 'job:test:reset', id: 1, state: 'reset', finished_at: now.utc.to_s)
      reporter.on_finish(:reset)
    end

    it 'publishes "job:test:finsish" with state "failed" if result is :errored' do
      expect(publishers).to receive(:state).with(0, 'job:test:finish', id: 1, state: 'errored', finished_at: now.utc.to_s)
      reporter.on_finish(:errored)
    end

    it 'publishes an empty log part with the :final flag set' do
      expect(publishers).to receive(:log).with(0, 'job:test:log', id: 1, number: 0, log: '', final: true)
      reporter.on_finish(0)
    end
  end

  describe 'on_cancel' do
    it 'publishes "job:test:log" with a cancelation notice' do
      expect(publishers).to receive(:log).with(0, 'job:test:log', id: 1, number: 0, log: "\n\e[33;1mCanceled.\e[0m\n")
      reporter.on_cancel
    end
  end

  describe 'on_notice' do
    it 'publishes "job:test:log" with the given message' do
      expect(publishers).to receive(:log).with(0, 'job:test:log', id: 1, number: 0, log: "\n\e[32;1mNotice:\e[0m some notice.\n")
      reporter.on_notice('some notice.')
    end
  end

  describe 'on_warning' do
    it 'publishes "job:test:log" with the given message' do
      expect(publishers).to receive(:log).with(0, 'job:test:log', id: 1, number: 0, log: "\n\e[33;1mWarning:\e[0m some warning.\n")
      reporter.on_warning('some warning.')
    end
  end

  describe 'on_error' do
    it 'publishes "job:test:log" with the given message' do
      expect(publishers).to receive(:log).with(0, 'job:test:log', id: 1, number: 0, log: "\n\e[31;1mError:\e[0m some error.\n")
      reporter.on_error('some error.')
    end
  end

  describe 'log' do
    it 'adds the given log output to the buffer' do
      expect(reporter.buffer).to receive(:<<).with('foo')
      reporter.log('foo')
    end

    it 'updates last_logged_at' do
      reporter.log('foo')
      expect(reporter.last_logged_at).to eq(now)
    end

    it 'flushes the buffer if the buffer interval is 0' do
      allow(config[:logs]).to receive(:[]).with(:buffer).and_return 0
      expect(reporter.buffer).to receive(:flush)
      reporter.log('foo')
    end

    it 'does not flush the buffer if the buffer interval is greater than 0' do
      allow(config[:logs]).to receive(:[]).with(:buffer).and_return 1
      expect(reporter.buffer).to_not receive(:flush)
      reporter.log('foo')
    end
  end

  describe 'log_length' do
    it "returns the buffer's total length" do
      reporter.log('foo')
      reporter.buffer.flush
      reporter.log('bar')
      expect(reporter.log_length).to eq(6)
    end
  end
end


