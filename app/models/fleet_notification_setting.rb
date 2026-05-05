# frozen_string_literal: true

class FleetNotificationSetting < ApplicationRecord
  belongs_to :fleet, touch: true

  serialize :enabled_in_app_events, coder: YAML
  serialize :enabled_discord_events, coder: YAML

  encrypts :discord_webhook_url

  DEFAULT_IN_APP_EVENTS = %w[
    fleet_event.published
    fleet_event.locked
    fleet_event.starting_soon
    fleet_event.cancelled
    fleet_event_signup.created
    fleet_event_signup.withdrawn
  ].freeze

  def in_app_enabled?(event_name)
    Array(enabled_in_app_events).include?(event_name)
  end

  def discord_enabled?(event_name)
    return false if discord_webhook_url.blank?

    Array(enabled_discord_events).include?(event_name)
  end
end
