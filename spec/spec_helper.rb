ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'rails/all'
require 'simple_google_auth'

SimpleGoogleAuth.configure do |c|
  c.client_id = '123'
  c.redirect_uri = '/abc'
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  # Specs mutate the global SimpleGoogleAuth.config; give each example a
  # fresh copy and restore the original afterwards so no example can leak
  # configuration into another.
  config.around do |example|
    original = SimpleGoogleAuth.config
    copy = original.dup
    copy.request_parameters = original.request_parameters.dup if original.request_parameters
    SimpleGoogleAuth.config = copy
    example.run
  ensure
    SimpleGoogleAuth.config = original
  end
end
