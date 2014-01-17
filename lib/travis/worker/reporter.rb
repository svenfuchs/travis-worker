require 'travis/worker/reporter/dispatcher'
require 'travis/worker/reporter/buffer'

module Travis
  class Worker
    class Reporter
      def self.create(num, config)
        new(num, config, Dispatcher.new(config))
      end

      attr_reader :num, :config, :job_id, :dispatcher, :buffer, :started_at, :last_logged_at

      def initialize(num, config, dispatcher)
        @num = num
        @config = config
        @dispatcher = dispatcher
        @buffer = Buffer.new(config[:logs] || {}, &method(:publish_logs))
      end

      def start(job_id)
        @job_id = job_id
        reset
        buffer.start
      end

      def on_boot
        publish_state 'job:test:boot', id: job_id, state: 'booted', booted_at: Time.now.utc.to_s
      end

      def on_start
        publish_state 'job:test:start', id: job_id, state: 'started', started_at: Time.now.utc.to_s
      end

      def on_finish(result)
        buffer.stop
        state = normalize_result(result)
        event = state == 'reset' ? 'reset' : 'finish'
        publish_state "job:test:#{event}", id: job_id, state: state, finished_at: Time.now.utc.to_s
        publish_logs buffer.part + 1, '', true
      end

      def on_cancel
        log "\n#{ansi_color(COLORS[:warning], 'Canceled.')}\n"
        buffer.stop
      end

      %i(notice warning error).each do |level|
        define_method(:"on_#{level}") { |message| log prefix(level, message) }
      end

      def log(log)
        @last_logged_at = Time.now
        buffer << log
        buffer.flush unless buffer.async?
      end

      def log_length
        buffer.length
      end

      private

        def reset
          @last_logged_at = Time.now
          @started_at = Time.now
        end

        def publish_state(event, payload)
          dispatcher.state(num, event, payload)
        end

        def publish_logs(part, log, final = false)
          payload = { id: job_id, number: part, log: log }
          payload[:final] = true if final
          dispatcher.log(num, 'job:test:log', payload)
        end

        STATES = %w(passed failed errored)

        def normalize_result(result)
          result.is_a?(Fixnum) ? STATES[result] || 'errored' : (result || 'errored').to_s
        end

        COLORS = { error: :red, warning: :yellow, notice: :green }
        COLOR_CODES = { red: 31, green: 32, yellow: 33 }

        def prefix(level, message)
          "\n#{ansi_color(COLORS[level], "#{level.to_s.sub(/^./) { |char| char.upcase }}:")} #{message}\n"
        end

        def ansi_color(name, string)
          "\033[#{COLOR_CODES[name]};1m#{string}\033[0m"
        end
    end
  end
end
