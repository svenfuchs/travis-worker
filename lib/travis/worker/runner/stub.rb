require 'open3'

module Travis
  class Worker
    class Runner
      class Stub < Runner
        def execute
          super
          status = nil
          Open3.popen3(command.build(payload)) do |stdin, stdout, stderr, wait_thr|
            reporter.log stdout.read
            status = wait_thr.value
          end
          status.exitstatus
        end
      end
    end
  end
end

