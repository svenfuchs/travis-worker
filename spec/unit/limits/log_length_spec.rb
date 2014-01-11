require 'spec_helper'
require 'travis/worker/limits/log_length'

describe Travis::Worker::Limits::LogLength do
  let(:config)   { { log_length: 20 } }
  let(:reporter) { double('reporter') }
  let(:limit)    { Travis::Worker::Limits::LogLength.new(reporter, config) }

  describe 'exceeded?' do
    it "returns false if the reporter's log_length is lesser than the allowed limit" do
      allow(reporter).to receive(:log_length).and_return(10)
      expect(limit.exceeded?).to be_false
    end

    it "returns true if the reporter's log_length is greater than the allowed limit" do
      allow(reporter).to receive(:log_length).and_return(30)
      expect(limit.exceeded?).to be_true
    end
  end

  describe 'error_msg' do
    it 'returns the error message' do
      # expect(limit.error_msg).to include('log length has exceeded the limit')
      expect(limit.error_msg).to match(/log length has exceeded the limit of \d+ MB/)
    end
  end
end
