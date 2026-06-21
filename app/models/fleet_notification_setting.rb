# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_notification_settings
#
#  id                    :uuid             not null, primary key
#  discord_webhook_url   :text
#  enabled_in_app_events :text             default(["fleet_event.published", "fleet_event.locked", "fleet_event.starting_soon", "fleet_event.cancelled", "fleet_event_signup.created", "fleet_event_signup.withdrawn"])
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  discord_channel_id    :string
#  discord_guild_id      :string
#  fleet_id              :uuid             not null
#
# Indexes
#
#  index_fleet_notification_settings_on_fleet_id  (fleet_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
class FleetNotificationSetting < ApplicationRecord
  belongs_to :fleet, touch: true

  serialize :enabled_in_app_events, coder: YAML

  encrypts :discord_webhook_url

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
end
