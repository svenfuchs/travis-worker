require 'travis/worker/receiver/commands'
require 'travis/worker/receiver/builds'

module Travis
  class Worker
    attr_reader :receivers

    def initialize(config)
      trap_signals

      commands = Receiver::Commands.create(0, config)
      @receivers = [commands]

      hosts = config.delete(:hosts)
      hosts.each do |host|
        config[:ssh] = host[:ssh]
        config[:hostname] = config[:ssh] ? config[:ssh][:host] : `hostname`.chomp

        1.upto(host[:vms]).map do |num|
          receivers << Receiver::Builds.create(num, config)
          commands.subscribers << receivers.last
        end

        Runner::Docker.cleanup_periodically(config) if config[:runner] == 'docker'
      end
    end

    def trap_signals
      Signal.trap('TERM', &method(:stop_gracefully))
    end

    def stop_gracefully
      receivers.each(&:unsubscribe)
      sleep 0.5 while receivers.any?(&:busy?)
      exit
    end
  end
end

if $0 == __FILE__
  require 'logger'
  require 'yaml'
  require 'core_ext/hash/deep_symbolize_keys'

  config = YAML.load_file('config/worker.yml').deep_symbolize_keys

  if [:receiver, :reporter].any? { |key| Array(config[key]).flatten.include?('amqp') }
    require 'travis/worker/utils/amqp'
    Travis::Worker::Amqp.connect(config[:amqp])
  end

  Travis::Worker.logger = Logger.new('worker.log')

  worker = Travis::Worker.new(config)

  puts 'Started.'
  sleep
end

