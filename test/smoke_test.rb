# frozen_string_literal: true

require "test_helper"

class SmokeTest < ActiveSupport::TestCase
  test "Rails environment is loaded in test mode" do
    assert_equal "test", Rails.env
  end

  test "FactoryBot is wired up" do
    user = build(:user)
    assert_kind_of User, user
  end

  test "shoulda-matchers is loaded" do
    assert defined?(Shoulda::Matchers::Integrations::TestFrameworks::Minitest5)
  end

  test "Sidekiq is in fake testing mode" do
    assert Sidekiq::Testing.fake?
  end
end
