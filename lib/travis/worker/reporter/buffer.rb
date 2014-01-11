require 'core_ext/kernel/periodically'
require 'travis/worker/utils/chunkifier'

module Travis
  class Worker
    class Reporter
      class Buffer
        attr_reader :config, :buffer, :pos, :part, :callback, :thread

        def initialize(config, &block)
          @config = config
          @callback = block
        end

        def async?
          config[:buffer].to_i > 0
        end

        def start
          reset
          @thread = run_periodically(config[:buffer]) { flush } if async?
        end

        def stop
          @stopped = true
          thread.kill if thread
          flush
        end

        def <<(string)
          buffer << string unless @stopped
        end

        def flush
          return unless pos < length
          string = buffer[pos, length - pos]
          @pos += string.length
          chunks(string).each do |chunk|
            @part += 1
            callback.call(part, chunk)
          end
        rescue => e
          puts e.message, e.backtrace
        end

        def length
          buffer.length
        end

        private

          def reset
            @buffer = ''
            @part = -1
            @pos = 0
            @stopped = false
          end

          def chunks(string)
            Chunkifier.new(string, config[:chunk_size] || 9216, json: true)
          end
      end
    end
  end
end
