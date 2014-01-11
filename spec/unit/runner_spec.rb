require 'spec_helper'
require 'travis/worker/runner'

describe Travis::Worker::Runner do
  include AsyncRunHelpers

  let(:config)   { {} }
  let(:reporter) { double('reporter', start: nil, log: nil) }
  let(:command)  { double('command') }
  let(:limits)   { Travis::Worker::Limits.new(reporter, config[:limits]) }
  let(:runner)   { described_class.new(0, config, reporter, limits, command) }
  let(:payload)  { { job: { id: 1 }, repository: { slug: 'travis-ci/travis-ci' } } }

  def run(payload)
    runner.run(payload)
  end

  before :each do
    %i(boot start finish halt cancel notice warning error).each do |event|
      allow(reporter).to receive(:"on_#{event}")
    end
  end

  describe 'runs_job?' do
    it 'returns true if the given job_id matches the current payload' do
      while_running(payload) do
        sleep 0.01
        expect(runner.runs_job?(1)).to be_true
      end
    end

    it 'returns false if the given job_id does not match the current payload' do
      while_running(payload) do
        sleep 0.01
        expect(runner.runs_job?(2)).to be_false
      end
    end

    it 'returns false if the runner does not run any job' do
      expect(runner.runs_job?(1)).to be_false
    end
  end

  describe 'run' do
    it 'checks the payload' do
      config = double('config')
      expect(Travis::Worker::Runner::Config).to receive(:new).and_return(config)
      expect(config).to receive(:check).with(payload)
      runner.run(payload)
    end

    it 'starts the reporter' do
      expect(reporter).to receive(:start).with(payload[:job][:id])
      runner.run(payload)
    end

    it 'boots' do
      expect(runner).to receive(:boot)
      runner.run(payload)
    end

    it 'checks periodically on limits' do
      expect(limits).to receive(:check_periodically)
      runner.run(payload)
    end

    it 'executes the build' do
      expect(runner).to receive(:execute)
      runner.run(payload)
    end

    describe 'a successful build' do
      before :each do
        allow(runner).to receive(:execute).and_return(0)
      end

      it 'reports the finish event with the result 0 to the reporter' do
        expect(reporter).to receive(:on_finish).with(0)
        runner.run(payload)
      end
    end

    describe 'an errored build' do
      before :each do
        allow(runner).to receive(:execute).and_raise('error')
      end

      it 'halts the runner' do
        expect(runner).to receive(:halt)
        runner.run(payload)
      end

      it 'reports the error message to the reporter' do
        expect(reporter).to receive(:on_error).with(/error/)
        runner.run(payload)
      end

      it 'finishes with the :reset for restartable exceptions' do
        allow(runner).to receive(:execute).and_raise(Travis::Worker::RestartableError.new('error'))
        expect(reporter).to receive(:on_finish).with(:reset)
        runner.run(payload)
      end

      it 'finishes with :errored on normal exceptions' do
        allow(runner).to receive(:execute).and_raise('error')
        expect(reporter).to receive(:on_finish).with(:errored)
        runner.run(payload)
      end
    end

    describe 'an canceled build' do
      it 'halts the runner' do
        expect(runner).to receive(:halt)
        while_running(payload) { runner.cancel }
      end

      it 'reports the cancel event to the reporter' do
        expect(reporter).to receive(:on_cancel)
        while_running(payload) { runner.cancel }
      end

      it 'finishes with :canceled' do
        expect(reporter).to receive(:on_finish).with(:canceled)
        while_running(payload) { runner.cancel }
      end
    end
  end
end
