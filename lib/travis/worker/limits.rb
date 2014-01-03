require 'core_ext/string/camelize'
require 'core_ext/kernel/periodically'

module Travis
  class Worker
    class Limits < Struct.new(:reporter, :config)
      require 'travis/worker/limits/log_length'
      require 'travis/worker/limits/log_silence'
      require 'travis/worker/limits/timeout'

      def check_periodically(&block)
        @thread = run_periodically(1) { check_all }
        # join both threads so exceptions will be raised from both of them
        [@thread, subject(&block)].map(&:join).last.value
      end

      private

        def check_all
          limits.each do |limit|
            raise LimitExceededError, limit.error_msg if limit.exceeded?
          end
        end

        def limits
          @limits ||= config.keys.map do |key|
            self.class.const_get(key.to_s.camelize).new(reporter, config)
          end
        end

        def subject
          Thread.new do
            begin
              yield
            ensure
              @thread.kill
            end
          end
        end
    end
  end
end

