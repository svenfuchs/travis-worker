require 'logger'

module Travis
  class Worker
    def self.logger
      @logger
    end

    def self.logger=(logger)
      @logger = logger
    end

    module Logging
      def logger
        Travis::Worker.logger
      end
    end
  end
end
