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
    citizenid: 5,
    patreon: 6
  }

  validates :provider, presence: true, uniqueness: {scope: :user_id}

  # One Patreon account, one Fleetyards account. Elsewhere a shared identity
  # would only be an odd sign-in; here it is two people with a claim on the
  # same pledge, and the linker would hand it to whichever the lookup returned.
  # The connection is refused rather than resolved -- handle_connect already
  # reports a failed save back to the user.
  validates :uid, uniqueness: {scope: :provider}, if: :patreon?

  # Linking an account changes no membership, so without this a member who
  # links Discord after being accepted never receives the roles their fleets
  # already mapped.
  after_create_commit :backfill_discord_member_roles, if: :discord?
  after_create_commit :link_patreon_contributions, if: :patreon?

  # Connecting proves which Patreon account this is, which is the one thing a
  # typed address never could -- so a contribution already synced under that
  # account can be claimed on the spot.
  private def link_patreon_contributions
    SupporterContribution
      .where(user_id: nil, patreon_user_id: uid)
      .find_each { |contribution| ::Supporters::Linker.call(contribution) }
  end

  private def backfill_discord_member_roles
    ::Discord::BackfillUserMemberRolesJob.perform_async(user_id)
  end
end
