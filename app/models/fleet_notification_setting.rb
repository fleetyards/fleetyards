# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_notification_settings
#
#  id                     :uuid             not null, primary key
#  discord_webhook_url    :text
#  enabled_in_app_events  :text             default("---\n- fleet_event.published\n- fleet_event.locked\n- fleet_event.starting_soon\n- fleet_event.cancelled\n- fleet_event_signup.created\n- fleet_event_signup.withdrawn")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  discord_channel_id     :string
#  discord_guild_id       :string
#  discord_member_role_id :string
#  fleet_id               :uuid             not null
#
# Indexes
#
#  index_fleet_notification_settings_on_discord_guild_id  (discord_guild_id)
#  index_fleet_notification_settings_on_fleet_id          (fleet_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
class FleetNotificationSetting < ApplicationRecord
  belongs_to :fleet, touch: true

  serialize :enabled_in_app_events, coder: YAML

  encrypts :discord_webhook_url

  # Mapping a role is a configuration change, not a membership change, so
  # nothing else would apply it to the members the fleet already has.
  after_commit :backfill_discord_member_roles, if: :saved_change_to_discord_member_role_id?

  DEFAULT_IN_APP_EVENTS = %w[
    fleet_event.published
    fleet_event.locked
    fleet_event.starting_soon
    fleet_event.cancelled
    fleet_event_signup.created
    fleet_event_signup.withdrawn
  ].freeze

  AVAILABLE_PRIVILEGES = [
    "fleet:notifications:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:notifications:manage"],
    member: []
  }.freeze

  def in_app_enabled?(event_name)
    Array(enabled_in_app_events).include?(event_name)
  end

  private def backfill_discord_member_roles
    return if discord_guild_id.blank?

    ::Discord::BackfillFleetMemberRolesJob.perform_async(fleet_id)
  end
end
