ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "./support/factory_bot"
require_relative "./support/authentication_helper"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end
