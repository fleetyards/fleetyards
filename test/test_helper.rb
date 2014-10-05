ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require "rails/test_help"
require "minitest/rails"
require "webmock/minitest"

require "active_record/fixtures"

class ActionController::TestCase
  include Devise::TestHelpers
  ActiveRecord::Migration.check_pending!
end
