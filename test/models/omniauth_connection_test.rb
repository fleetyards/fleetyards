# frozen_string_literal: true

require "test_helper"

class OmniauthConnectionTest < ActiveSupport::TestCase
  should belong_to(:user)

  test "enforces one connection per provider per user" do
    connection = create(:omniauth_connection, provider: :discord)
    duplicate = build(:omniauth_connection, user: connection.user, provider: :discord)

    refute duplicate.valid?
    assert duplicate.errors[:provider].present?
  end

  test "allows same provider for different users" do
    create(:omniauth_connection, provider: :discord)
    other = build(:omniauth_connection, provider: :discord)

    assert other.valid?
  end

  test "provider enum defines expected providers" do
    assert_equal({
      "google" => 0,
      "discord" => 1,
      "github" => 2,
      "bluesky" => 3,
      "twitch" => 4,
      "citizenid" => 5
    }, OmniauthConnection.providers)
  end
end
