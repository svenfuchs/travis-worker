require 'spec_helper'
require 'travis/worker/limits'

describe Travis::Worker::Limits do
  let(:config)   { { log_length: 10, interval: 0 } }
  let(:reporter) { double('reporter', log_length: 0) }
  let(:limit)    { double('limit', error_msg: 'error', exceeded?: false) }
  let(:limits)   { Travis::Worker::Limits.new(reporter, config) }

  describe 'check_periodically' do
    it "returns the block's return value" do
      result = limits.check_periodically { sleep 0.001 }
      expect(result).to be_true
    end

    it "raises a LimitExceededError when any of the limits is exceeded" do
      allow(limits).to receive(:limits).and_return([limit])
      allow(limit).to receive(:exceeded?).and_return(true)
      expect { limits.check_periodically { sleep } }.to raise_error(Travis::Worker::LimitExceededError)
    end
  end
end

