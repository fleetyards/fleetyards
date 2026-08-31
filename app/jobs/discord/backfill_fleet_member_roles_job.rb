# frozen_string_literal: true

module Discord
  # Applies a fleet's role mapping to the members it already has.
  #
  # The per-membership sync is event-driven: it fires when a state or a rank
  # changes. That is the wrong direction for a rollout -- a fleet maps a role
  # and nothing happens, because no membership changed. This is what makes
  # configuring a mapping take effect.
  class BackfillFleetMemberRolesJob < ::ApplicationJob
    sidekiq_options retry: 1, queue: "notifications"

    # One membership costs a get_guild_member plus a call per role change, so a
    # large fleet is spread over time rather than fired at Discord at once.
    PER_SECOND = 10

    # Positional on purpose: Sidekiq replays arguments positionally. A role id
    # narrows the backfill to the members holding that rank, which is all a
    # single rank mapping can affect.
    def perform(fleet_id, fleet_role_id = nil)
      return unless ApiClient.configured?

      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?
      return if fleet.fleet_notification_setting&.discord_guild_id.blank?

      ids = membership_ids(fleet, fleet_role_id)
      return if ids.empty?

      Rails.logger.info("[Discord::BackfillFleetMemberRolesJob] fleet=#{fleet_id} members=#{ids.size}")

      ids.each_with_index do |membership_id, index|
        SyncMemberRolesJob.perform_in((index / PER_SECOND.to_f).seconds, membership_id)
      end
    end

    # Only accepted members who actually linked a Discord account: a sync for
    # anyone else is a job that can only decide to do nothing.
    private def membership_ids(fleet, fleet_role_id)
      scope = fleet.fleet_memberships
        .kept
        .where(aasm_state: "accepted")
        .joins(user: :omniauth_connections)
        .where(omniauth_connections: {provider: OmniauthConnection.providers[:discord]})

      scope = scope.where(fleet_role_id: fleet_role_id) if fleet_role_id.present?

      scope.distinct.pluck(:id)
    end
  end
end
