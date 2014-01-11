require 'spec_helper'
require 'travis/worker/runner/config'

describe Travis::Worker::Runner::Config do
  let(:reporter) { double('reporter') }
  let(:config)   { described_class.new(reporter) }

  describe 'check' do
    it 'raises if the .travis.yml file could not be parsed' do
      check = -> { config.check(config: { :'.result' => 'parse_error' }) }
      expect(&check).to raise_error(Travis::Worker::ConfigParseError)
    end

    it 'logs a warning if no .travis.yml file has found' do
      expect(reporter).to receive(:on_warning).with(/unable to find a .travis.yml file/)
      config.check(config: { :'.result' => 'not_found' })
    end
  end
end
