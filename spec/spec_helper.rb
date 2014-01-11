require 'spec_helpers/amqp_helpers'
require 'spec_helpers/async_run_helpers'
require 'spec_helpers/stub_time'

RSpec.configure do |c|
  c.filter_run_excluding jruby: true unless defined?(JRuby)
end
