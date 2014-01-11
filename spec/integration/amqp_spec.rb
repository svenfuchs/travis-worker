require 'spec_helper'
require 'travis/worker'
require 'integration/shared_examples'

describe 'Running a job in memory', jruby: true do
  include AmqpHelpers
  include AsyncRunHelpers
  include StubTime

  let(:config) do
    {
      hostname: 'hostname',
      command: 'echo "Build output"',
      hosts: [{ vms: 1 }],
      receiver: { builds: :amqp, commands: :amqp },
      runner: :stub,
      reporter: { state: [:amqp, :memory], log: :amqp }
    }
  end

  let!(:worker)    { Travis::Worker.new(config) }
  let(:states)     { amqp.states.receive }
  let(:logs)       { amqp.logs.receive }
  let(:payload)    { { job: { id: 1 }, repository: { slug: 'travis-ci/travis-ci' } } }

  def run(payload)
    amqp.builds.publish(payload)
    wait_for_build_finished
    sleep 0.1
  end

  def command(payload)
    amqp.commands.publish(payload)
  end

  before :each do
    Travis::Worker::Amqp.connect
    amqp.purge
  end

  after :each do
    amqp.purge
    Travis::Worker::Amqp.disconnect
  end

  it_behaves_like 'state updates'
  it_behaves_like 'log messages'
  # it_behaves_like 'job cancelation'
  # it_behaves_like 'limits: timeout'
  # it_behaves_like 'limits: log_length'
  # it_behaves_like 'limits: log_silence'
end
