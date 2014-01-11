require 'spec_helper'
require 'travis/worker/limits/timeout'

describe Travis::Worker::Limits::Timeout do
  let(:config)   { { timeout: 20 } }
  let(:reporter) { double('reporter') }
  let(:limit)    { Travis::Worker::Limits::Timeout.new(reporter, config) }

  describe 'exceeded?' do
    it "returns false if the build has started less than the allowed number of seconds ago" do
      allow(reporter).to receive(:started_at).and_return(Time.now - 10)
      expect(limit.exceeded?).to be_false
    end

    it "returns false if the build has started longer than the allowed number of seconds ago" do
      allow(reporter).to receive(:started_at).and_return(Time.now - 30)
      expect(limit.exceeded?).to be_true
    end
  end

  describe 'error_msg' do
    it 'returns the error message' do
      expect(limit.error_msg).to match(/Execution expired after \d+ minutes/)
    end
  end
end
