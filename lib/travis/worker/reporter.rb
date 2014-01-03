require 'travis/worker/reporter/dispatch'
require 'travis/worker/reporter/buffer'

module Travis
  class Worker
    class Reporter
      def self.create(num, config)
        new(num, config, Dispatch.new(config))
      end

      attr_reader :num, :config, :dispatch, :buffer
      attr_accessor :job_id

      def initialize(num, config, dispatch)
        @num = num
        @config = config
        @dispatch = dispatch
        @buffer = Buffer.new(config[:logs], &method(:publish_logs))
      end

      def on_start(job_id)
        @job_id = job_id
        buffer.start
        publish_state 'job:test:start', id: job_id, state: 'started', started_at: Time.now.utc
        log "Using worker: #{config[:hostname]}:#{num}\n"
      end

      def on_finish(result)
        buffer.stop
        state = normalize_result(result)
        event = state == 'reset' ? 'reset' : 'finish'
        publish_state "job:test:#{event}", id: job_id, state: state, finished_at: Time.now.utc
      end

      def on_cancel
        log ansi_color(COLORS[:warn], "\nCanceled.")
      end

      def on_warning(message)
        log prefix(:warn, message)
      end

      def on_error(message)
        log prefix(:error, message)
      end

      def log(log)
        buffer << log
        buffer.flush if config[:logs][:buffer] == 0
      end

      def log_length
        buffer.length
      end

      def last_logged_at
        buffer.mtime
      end

      private

        def publish_state(event, payload)
          dispatch.publish(:state, num, event, payload)
        end

        def publish_logs(part, log, final = false)
          payload = { id: job_id, number: part, log: log }
          payload[:final] = true if final
          dispatch.publish(:log, num, payload)
        end

        STATES = %w(passed failed errored)

        def normalize_result(result)
          result.is_a?(Fixnum) ? STATES[result] || 'errored' : result.to_s
        end

        PREFIX = { error: 'Error', warn: 'Warning' }
        COLORS = { error: 31, warn: 33 }

        def prefix(level, message)
          "\n#{ansi_color(COLORS[level], "#{PREFIX[level]}:")} #{message}\n"
        end

        def ansi_color(color, string)
          "\033[#{color};1m#{string}\033[0m"
        end
    end
  end
end
