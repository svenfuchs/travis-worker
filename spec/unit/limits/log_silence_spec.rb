require 'spec_helper'
require 'travis/worker/limits/log_silence'

describe Travis::Worker::Limits::LogSilence do
  let(:config)   { { log_silence: 20 } }
  let(:reporter) { double('reporter') }
  let(:limit)    { Travis::Worker::Limits::LogSilence.new(reporter, config) }

  describe 'exceeded?' do
    it "returns false if the reporter's last_logged_at is past less than the allowed number of seconds" do
      allow(reporter).to receive(:last_logged_at).and_return(Time.now - 10)
      expect(limit.exceeded?).to be_false
    end

    it "returns true if the reporter's last_logged_at is past longer than the allowed number of seconds" do
      allow(reporter).to receive(:last_logged_at).and_return(Time.now - 30)
      expect(limit.exceeded?).to be_true
    end
  end

  describe 'error_msg' do
    it 'returns the error message' do
      expect(limit.error_msg).to match(/No output has been received in the last \d+ minutes/)
    end
  end
end
