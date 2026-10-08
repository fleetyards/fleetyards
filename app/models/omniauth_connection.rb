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

  # The users linked to each of these Discord accounts, by Discord user id.
  def self.discord_users(uids)
    discord.where(uid: uids).includes(:user).group_by(&:uid).transform_values { |connections| connections.map(&:user) }
  end

  # Linking an account changes no membership, so without this a member who
  # links Discord after being accepted never receives the roles their fleets
  # already mapped.
  after_create_commit :backfill_discord_member_roles, if: :discord?
  # Linking is the first moment a fleet's join role can be seen on someone.
  after_create_commit :apply_discord_join_roles, if: :discord?
  after_create_commit :link_patreon_contributions, if: :patreon?
  # A user being deleted loses its memberships before its connections, so
  # User captures the fleets itself and this hook stands aside.
  after_destroy_commit :revoke_discord_member_roles, if: -> { discord? && destroyed_by_association.nil? }

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

  private def apply_discord_join_roles
    ::Discord::ApplyJoinRolesJob.perform_async(uid)
  end

  private def revoke_discord_member_roles
    ::Discord::RevokeMemberRolesJob.perform_async(uid, user.fleet_memberships.pluck(:fleet_id).uniq)
  end
end
