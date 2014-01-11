require 'spec_helper'
require 'travis/worker/reporter/buffer'

describe Travis::Worker::Reporter::Buffer do
  let(:log)    { [] }
  let(:config) { { buffer: 0, chunk_size: 5 } }
  let(:buffer) { described_class.new(config) { |*args| log << args } }

  before :each do
    buffer.start
  end

  describe 'flush' do
    it 'flushes chunks with part numbers to the callback' do
      buffer << 'foo'
      buffer.flush
      expect(log.first).to eq([0, 'foo'])
    end

    it 'splits large strings into chunks according to the config chunk_size' do
      buffer << 'a' * 15
      buffer.flush
      expect(log.map { |chunk| chunk[1].size }).to eq([3, 3, 3, 3, 3]) # TODO ummm, interesting. ask Piotr about this.
    end
  end

  describe 'stop' do
    it 'flushes the buffer' do
      buffer << 'foo'
      buffer.stop
      expect(log.first).to eq([0, 'foo'])
    end
  end
end
