module Kernel
  def run_periodically(interval, &block)
    Thread.new do
      periodically(interval, &block)
    end
  end

  def periodically(interval)
    loop do
      sleep interval
      yield
    end
  end
end
