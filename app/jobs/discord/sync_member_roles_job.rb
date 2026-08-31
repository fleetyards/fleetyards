# frozen_string_literal: true

require "discord/member_role_sync"

module Discord
  # Applies one member's Discord roles.
  class SyncMemberRolesJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(membership_id)
      membership = FleetMembership.find_by(id: membership_id)
      return if membership.blank?

      sync = MemberRoleSync.new(membership)
      return unless sync.runnable?

      result = sync.run!
      return if result.added.blank? && result.removed.blank?

      Rails.logger.info("[Discord::SyncMemberRolesJob] membership=#{membership_id} #{result}")
    rescue ApiClient::Error => e
      Rails.logger.error("[Discord::SyncMemberRolesJob] membership=#{membership_id} failed: #{e.message}")
      raise if e.status == 429 || e.status >= 500
    end
  end
end
