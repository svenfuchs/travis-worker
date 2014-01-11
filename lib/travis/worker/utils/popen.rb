require 'travis/worker/utils/jruby_process'

module Travis
  class Worker
    module Popen
      def popen(cmd)
        process = JRubyProcess.new(cmd)
        process.start
        process
      end

      extend self
    end
  end
end
