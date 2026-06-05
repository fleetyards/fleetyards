# frozen_string_literal: true

require "test_helper"

class RailsAppCredsIntegrationTest < ActiveSupport::TestCase
  test "Rails.app is an alias for Rails.application" do
    assert_equal Rails.application, Rails.app
  end

  test "Rails.app exposes a creds accessor" do
    assert_kind_of RailsCredsBackport::CombinedConfiguration, Rails.app.creds
  end

  test "Rails.app exposes an envs accessor" do
    assert_kind_of RailsCredsBackport::EnvConfiguration, Rails.app.envs
  end

  test "creds looks up ENV values" do
    ENV["RAILS_CREDS_BACKPORT_TEST"] = "it_works"
    Rails.app.envs.reload
    Rails.app.creds = nil

    assert_equal "it_works", Rails.app.creds.option(:rails_creds_backport_test)
  ensure
    ENV.delete("RAILS_CREDS_BACKPORT_TEST")
    Rails.app.creds = nil
  end
end
