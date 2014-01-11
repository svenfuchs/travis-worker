require 'spec_helper'
require 'travis/worker'
require 'integration/shared_examples'

describe 'Running a job in memory' do
  include AsyncRunHelpers
  include StubTime

  let(:config) do
    {
      hostname: 'hostname',
      command: 'echo "Build output"',
      hosts: [{ vms: 1 }],
      receiver: { builds: :stub, commands: :stub },
      runner: :stub,
      reporter: { state: :memory, log: :memory }
    }
  end

  let(:worker)     { Travis::Worker.new(config) }
  let(:commands)   { worker.receivers.first }
  let(:builds)     { worker.receivers.last }
  let(:runner)     { builds.runner }
  let(:logs)       { runner.reporter.dispatcher.publishers[:log].first.data }
  let(:states)     { runner.reporter.dispatcher.publishers[:state].first.data }
  let(:payload)    { { job: { id: 1 }, repository: { slug: 'travis-ci/travis-ci' } } }

  def run(payload)
    builds.receive(payload)
  end

  def command(payload)
    commands.receive(payload)
  end

  it_behaves_like 'state updates'
  it_behaves_like 'log messages'
  it_behaves_like 'job cancelation'
  it_behaves_like 'limits: timeout'
  it_behaves_like 'limits: log_length'
  it_behaves_like 'limits: log_silence'
end
