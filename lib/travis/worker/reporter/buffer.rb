require 'core_ext/kernel/periodically'
require 'travis/worker/utils/chunkifier'

module Travis
  class Worker
    class Reporter
      class Buffer
        attr_reader :config, :buffer, :pos, :part, :callback, :thread, :mtime

        def initialize(config, &block)
          @config = config
          @callback = block
          @buffer = ''
          @mtime = Time.now
          @part = -1
          @pos = 0
        end

        def start
          @buffer = ''
          @mtime = Time.now
          @part = -1
          @pos = 0
          @thread = run_periodically(config[:buffer]) { flush } if config[:buffer] > 0
        end

        def stop
          thread.kill if thread
          flush
          callback.call(part + 1, '', true)
        end

        def <<(string)
          @mtime = Time.now
          buffer << string
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

        def chunks(string)
          Chunkifier.new(string, config[:chunk_size], json: true)
        end
      end
    end
  end
end
