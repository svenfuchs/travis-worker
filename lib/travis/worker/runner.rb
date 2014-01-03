require 'travis/build'
require 'core_ext/string/camelize'

require 'travis/worker/exceptions'
require 'travis/worker/limits'
require 'travis/worker/reporter'
require 'travis/worker/runner/docker'

module Travis
  class Worker
    class Runner
      def self.create(num, config)
        reporter = Reporter.create(num, config)
        limits = Limits.new(reporter, config[:limits])
        const_name = config[:runner].to_s.camelize
        const_get(const_name).new(num, config, reporter, limits)
      end

      attr_reader :num, :config, :limits, :reporter, :payload

      def initialize(num, config, reporter, limits)
        @num = num
        @config = config
        @reporter = reporter
        @limits = limits
      end

      def runs_job?(id)
        !canceled? && payload && payload[:job][:id] == id
      end

      def run(payload)
        @payload = payload
        announce 'Starting'
        reporter.on_start(payload[:job][:id])
        check_config
        result = limits.check_periodically { execute }
      rescue => e
        halt
        result = e.respond_to?(:result) ? e.result : :errored
        reporter.on_error(e.message)
      ensure
        result = :canceled if canceled?
        reporter.on_finish(result)
        announce 'Finished'
        @payload = nil
      end

      def cancel
        announce 'Cancelling'
        @canceled = true
        sleep 0.25
        reporter.on_cancel
        halt
      end

      def busy?
        !!@payload
      end

      private

        def canceled?
          !!@canceled
        end

        def cmd
          # data = payload.merge(timeouts: false, hosts: config[:hosts], cache_options: config[:cache_options])
          # Build.script(data, logs: { build: false, state: true }).compile
          'echo {0..100}; for i in {0..100}; do printf .; sleep 0.0$[ 1 + $[ RANDOM % 10 ]]; done'
        rescue => e
          raise CompileError, e
        end

        def check_config
          case payload[:config][:'.result']
          when 'parse_error'
            raise ConfigParseError
          when 'not_found'
            reporter.on_warning "We were unable to find a .travis.yml file. This may not be what you\nwant. The build will be run with default settings.\n\n"
          end
        end

        def announce(msg)
          puts "[worker-#{num}] #{msg} job: #{payload[:repository][:slug]}, id: #{payload[:job][:id]}"
        end
    end
  end
end

