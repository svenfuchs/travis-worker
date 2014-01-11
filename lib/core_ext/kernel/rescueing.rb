module Kernel
  def rescueing(*exceptions)
    exceptions << StandardError if exceptions.empty?
    yield
  rescue *exceptions => e
    puts e.message, e.backtrace
  end
end
