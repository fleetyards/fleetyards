# frozen_string_literal: true

module Discord
  # Applies every fleet's role mapping to one member, for the case the
  # per-membership sync cannot see: someone who links their Discord account
  # *after* being accepted. Nothing about their membership changed, so nothing
  # would otherwise give them the roles their fleets already mapped.
  class BackfillUserMemberRolesJob < ::ApplicationJob
    sidekiq_options retry: 1, queue: "notifications"

    def perform(user_id)
      return unless ApiClient.configured?

      user = User.find_by(id: user_id)
      return if user.blank?

      user.fleet_memberships.kept.where(aasm_state: "accepted").find_each do |membership|
        next if membership.fleet&.fleet_notification_setting&.discord_guild_id.blank?

        SyncMemberRolesJob.perform_async(membership.id)
      end
    end
  end
end
