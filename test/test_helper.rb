# encoding: utf-8
# frozen_string_literal: true

require 'simplecov'
require 'simplecov-console'
require 'simplecov-html'

formatters = [
  SimpleCov::Formatter::Console,
  SimpleCov::Formatter::HTMLFormatter
]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.start('rails')

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require "rails/test_help"
require "minitest/rails"

require "faker"

require "active_record/fixtures"

require 'sidekiq/testing'
Sidekiq::Testing.fake!

# helper
require "support/session_helper"
require "database_cleaner"

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end

# database cleaner
DatabaseCleaner.strategy = :transaction

# rubocop:disable Style/ClassAndModuleChildren
class ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include SessionHelper
  ActiveRecord::Migration.check_pending!

  fixtures :all

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end

class ActionView::TestCase
  include Devise::Test::ControllerHelpers

  fixtures :all

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  fixtures :all

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  after do
    Sidekiq::Worker.clear_all
  end
end
