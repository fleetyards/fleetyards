# frozen_string_literal: true

# == Schema Information
#
# Table name: omniauth_connections
#
#  id           :uuid             not null, primary key
#  auth_payload :jsonb
#  provider     :integer          not null
#  uid          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_omniauth_connections_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class OmniauthConnectionTest < ActiveSupport::TestCase
  # Connecting proves which Patreon account this is, so a contribution already
  # synced under it can be claimed on the spot rather than waiting for the next
  # campaign sync.
  test "connecting Patreon claims contributions already synced for that account" do
    user = create(:user, confirmed_at: Time.current)
    contribution = create(:supporter_contribution, :patreon, patreon_user_id: "patreon-user-1")

    assert_nil contribution.user

    create(:omniauth_connection, user: user, provider: :patreon, uid: "patreon-user-1")

    assert_equal user, contribution.reload.user
  end

  test "connecting Patreon leaves another account's contributions alone" do
    user = create(:user, confirmed_at: Time.current)
    other = create(:supporter_contribution, :patreon, patreon_user_id: "somebody-else")

    create(:omniauth_connection, user: user, provider: :patreon, uid: "patreon-user-1")

    assert_nil other.reload.user
  end

  test "connecting Patreon never takes a contribution that is already linked" do
    owner = create(:user, confirmed_at: Time.current)
    claimed = create(:supporter_contribution, :patreon,
      patreon_user_id: "patreon-user-1", user: owner)

    create(:omniauth_connection, user: create(:user, confirmed_at: Time.current),
      provider: :patreon, uid: "patreon-user-1")

    assert_equal owner, claimed.reload.user
  end

  test "connecting another provider claims nothing" do
    user = create(:user, confirmed_at: Time.current)
    contribution = create(:supporter_contribution, :patreon, patreon_user_id: "patreon-user-1")

    create(:omniauth_connection, user: user, provider: :github, uid: "patreon-user-1")

    assert_nil contribution.reload.user
  end
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
      "citizenid" => 5,
      "patreon" => 6
    }, OmniauthConnection.providers)
  end
end
