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
class OmniauthConnection < ApplicationRecord
  belongs_to :user, touch: true

  enum :provider, {
    google: 0,
    discord: 1,
    github: 2,
    bluesky: 3,
    twitch: 4,
    citizenid: 5
  }

  validates :provider, presence: true, uniqueness: {scope: :user_id}

  # Linking an account changes no membership, so without this a member who
  # links Discord after being accepted never receives the roles their fleets
  # already mapped.
  after_create_commit :backfill_discord_member_roles, if: :discord?

  private def backfill_discord_member_roles
    ::Discord::BackfillUserMemberRolesJob.perform_async(user_id)
  end
end
