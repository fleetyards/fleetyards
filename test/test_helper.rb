# frozen_string_literal: true

if ENV['RAILS_TEST_COVERAGE']
  require 'simplecov'
  require 'simplecov-console'
  require 'simplecov-html'

  formatters = [
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::HTMLFormatter
  ]
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
  SimpleCov.start('rails')
end

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)

require 'rails/test_help'
require 'minitest/rails'
require 'minitest/pride'

# https://github.com/rails/rails/issues/31324
Minitest::Rails::TestUnit = Rails::TestUnit if ActionPack::VERSION::STRING >= '5.2.0'

require 'faker'

require 'active_record/fixtures'

require 'sidekiq/testing'
Sidekiq::Testing.fake!

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock # or :fakeweb
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

# and disable callbacks
Searchkick.disable_callbacks

# rubocop:disable Style/ClassAndModuleChildren
class ActionController::TestCase
  include Devise::Test::ControllerHelpers
  ActiveRecord::Migration.check_pending!

  fixtures :all

  make_my_diffs_pretty!

  parallelize_setup do |worker|
    Searchkick.index_suffix = worker

    ShopCommodity.reindex

    # and disable callbacks
    Searchkick.disable_callbacks
  end
end
# rubocop:enable Style/ClassAndModuleChildren

# rubocop:disable Style/ClassAndModuleChildren
class ActionView::TestCase
  include Devise::Test::ControllerHelpers

  fixtures :all

  make_my_diffs_pretty!
end
# rubocop:enable Style/ClassAndModuleChildren

# rubocop:disable Style/ClassAndModuleChildren
class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  fixtures :all

  after do
    Sidekiq::Worker.clear_all
  end

  make_my_diffs_pretty!
end
# rubocop:enable Style/ClassAndModuleChildren
