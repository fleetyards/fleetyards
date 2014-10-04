ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require "rails/test_help"
require "minitest/rails"
require "webmock/minitest"

require "vcr"

# vcr
VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = "test/vcr"
  c.hook_into :webmock # or :fakeweb
  # c.debug_logger = File.open(Rails.root.join("log", "vcr.log"), "w")
end

require "active_record/fixtures"

class ActionController::TestCase
  include Devise::TestHelpers
  ActiveRecord::Migration.check_pending!
end
