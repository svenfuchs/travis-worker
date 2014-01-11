shared_examples_for 'state updates' do
  before :each do
    run(payload)
  end

  # it 'sends a boot event' do
  #   expect(states[0]).to eq(['job:test:boot', { id: 1, state: 'booted', booted_at: now.utc.to_s }])
  # end

  it 'sends a start event' do
    expect(states[0]).to eq(['job:test:start', { id: 1, state: 'started', started_at: now.utc.to_s }])
  end

  it 'sends a finish event' do
    expect(states[1]).to eq(['job:test:finish', { id: 1, state: 'passed', finished_at: now.utc.to_s }])
  end
end

shared_examples_for 'log messages' do
  before :each do
    run(payload)
  end

  it 'sends a worker announcement' do
    expect(logs[0]).to eq(['job:test:log', { id: 1, number: 0, log: "Using worker: hostname:1\n" }])
  end

  it 'sends the build output' do
    expect(logs[1]).to eq(['job:test:log', { id: 1, number: 1, log: "Build output\n" }])
  end

  it 'sends the final log part' do
    expect(logs[2]).to eq(['job:test:log', { id: 1, number: 2, log: '', final: true }])
  end
end

shared_examples_for 'job cancelation' do
  before :each do
    while_running(payload) { sleep 0.01; command(type: 'cancel_job', job_id: 1) }
  end

  it 'sends a finish event with the state: "canceled"' do
    expect(states[0]).to eq(['job:test:finish', { id: 1, state: 'canceled', finished_at: now.utc.to_s }])
  end

  it 'sends a log message about the cancellation' do
    expect(logs[1]).to eq(['job:test:log', id: 1, number: 1, log: "\n\e[33;1mCanceled.\e[0m\n"])
  end
end

shared_examples_for 'limits: timeout' do
  before :each do
    config.merge!(command: 'sleep 1', limits: { interval: 0.001, timeout: 0 })
    run(payload)
  end

  it 'sends a finish event with the state: "errored"' do
    expect(states[1]).to eq(['job:test:finish', { id: 1, state: 'errored', finished_at: now.utc.to_s }])
  end

  it 'halts the build when the log limit has been exceeded' do
    expect(logs[1][1][:log]).to match(/Execution expired after \d+ minutes/)
  end
end

shared_examples_for 'limits: log_length' do
  before :each do
    config.merge!(command: 'sleep 1', limits: { interval: 0.001, log_length: 0 })
    run(payload)
  end

  it 'sends a finish event with the state: "errored"' do
    expect(states[1]).to eq(['job:test:finish', { id: 1, state: 'errored', finished_at: now.utc.to_s }])
  end

  it 'halts the build when the log limit has been exceeded' do
    expect(logs[1][1][:log]).to match(/The log length has exceeded the limit of \d+ MB/)
  end
end

shared_examples_for 'limits: log_silence' do
  before :each do
    config.merge!(command: 'sleep 1', limits: { interval: 0.001, log_silence: 0 })
    run(payload)
  end

  it 'sends a finish event with the state: "errored"' do
    expect(states[1]).to eq(['job:test:finish', { id: 1, state: 'errored', finished_at: now.utc.to_s }])
  end

  it 'halts the build when the log limit has been exceeded' do
    expect(logs[1][1][:log]).to match(/No output has been received in the last \d+ minutes/)
  end
end
