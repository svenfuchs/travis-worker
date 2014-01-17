require 'core_ext/class/attr_initializer'
require 'core_ext/string/camelize'

require 'travis/worker/command'
require 'travis/worker/exceptions'
require 'travis/worker/limits'
require 'travis/worker/reporter'

require 'travis/worker/runner/config'
require 'travis/worker/runner/stub'
require 'travis/worker/runner/docker'

module Travis
  class Worker
    class Runner
      def self.create(num, config)
        reporter = Reporter.create(num, config)
        limits = Limits.new(reporter, config[:limits] || {})
        const_name = config[:runner].to_s.camelize
        command = Command.const_get(const_name).new(config)
        const_get(const_name).new(num, config, reporter, limits, command)
      end

      attr_initializer :num, :config, :reporter, :limits, :command
      attr_reader :payload

      def runs_job?(id)
        payload && payload[:job][:id] == id
      end

      def run(payload)
        @payload = payload
        reporter.start(payload[:job][:id])
        reporter.log "Using worker: #{config[:hostname]}:#{num}\n"
        Config.new(reporter).check(payload)
        # notice 'Starting'
        boot
        result = limits.check_periodically { execute }
      rescue => error
        error = RubyLandError.new(error) unless error.is_a?(WorkerError)
        halt
        result = error.result
        reporter.on_error(error.message)
      ensure
        finish(result)
      end

      def cancel
        @canceled = true
        reporter.on_cancel
        halt
        # notice 'Canceled'
      end

      def running?
        !!@payload
      end

      def canceled?
        !!@canceled
      end

      private

        def boot
          reporter.on_boot
        end

        def execute
          reporter.on_start
        end

        def halt
        end

        def finish(result)
          result = :canceled if canceled?
          reporter.on_finish(result)
          notice 'Finished'
          @payload = nil
          @canceled = nil
        end

        def notice(msg)
          # reporter.on_notice "#{msg} job: #{payload[:repository][:slug]}, id: #{payload[:job][:id]}"
        end
    end
  end
end
