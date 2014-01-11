require 'core_ext/kernel/rescueing'

module Kernel
  def run_periodically(interval, options = {}, &block)
    Thread.new do
      periodically(interval, options, &block)
    end
  end

  def periodically(interval, options = {}, &block)
    loop do
      sleep interval
      errors = options[:rescue] == true ? StandardError : options[:rescue]
      errors ? rescueing(*errors, &block) : yield
    end
  end
end

