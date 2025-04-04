ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "./support/factory_bot"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end
