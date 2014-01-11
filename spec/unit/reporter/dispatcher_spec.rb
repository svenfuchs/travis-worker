require 'spec_helper'
require 'travis/worker/reporter/dispatcher'

describe Travis::Worker::Reporter::Dispatcher do
  let(:config)           { { reporter: { log: [:memory, :memory], state: [:memory, :memory] } } }
  let(:dispatcher)       { described_class.new(config) }
  let(:log_publishers)   { dispatcher.publishers[:log] }
  let(:state_publishers) { dispatcher.publishers[:state] }


  it 'creates state publishers according to the config' do
    expect(log_publishers.map(&:class)).to eql([Travis::Worker::Reporter::Publisher::Memory] * 2)
  end

  it 'creates log publishers according to the config' do
    expect(state_publishers.map(&:class)).to eql([Travis::Worker::Reporter::Publisher::Memory] * 2)
  end

  describe 'state' do
    it 'publishes the given number, event and payload on each publisher' do
      args = ['job:test:start', foo: :bar]
      dispatcher.state(0, *args)
      expect(state_publishers.map(&:data).map(&:first)).to eq([args, args])
    end
  end

  describe 'log' do
    it 'publishes the given number, event and payload on each publisher' do
      args = ['job:test:log', log: 'log' ]
      dispatcher.log(0, *args)
      expect(log_publishers.map(&:data).map(&:first)).to eq([args, args])
    end
  end
end
