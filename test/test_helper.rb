# frozen_string_literal: true
ENV["RAILS_ENV"] = "test"
ENV["DEVISE_SECRET"] = "devise_secret"
ENV["SECRET_KEY_BASE"] = "secret"

require File.expand_path('../../config/environment', __FILE__)

require "rails/test_help"
require "minitest/rails"
require "webmock/minitest"

require "active_record/fixtures"

# rubocop:disable Style/ClassAndModuleChildren
class ActionController::TestCase
  include Devise::TestHelpers
  ActiveRecord::Migration.check_pending!
end
