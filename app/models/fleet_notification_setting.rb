# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_notification_settings
#
#  id                              :uuid             not null, primary key
#  discord_digest_sent_at          :datetime
#  discord_digest_time             :string
#  discord_digest_weekday          :integer
#  discord_webhook_url             :text
#  enabled_in_app_events           :text             default(["fleet_event.published", "fleet_event.locked", "fleet_event.starting_soon", "fleet_event.cancelled", "fleet_event_signup.created", "fleet_event_signup.withdrawn"])
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  discord_announcement_channel_id :string
#  discord_channel_id              :string
#  discord_guild_id                :string
#  discord_member_role_id          :string
#  discord_officers_channel_id     :string
#  fleet_id                        :uuid             not null
#
# Indexes
#
#  index_fleet_notification_settings_on_discord_digest_weekday  (discord_digest_weekday) WHERE (discord_digest_weekday IS NOT NULL)
#  index_fleet_notification_settings_on_discord_guild_id        (discord_guild_id)
#  index_fleet_notification_settings_on_fleet_id                (fleet_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
class FleetNotificationSetting < ApplicationRecord
  belongs_to :fleet, touch: true

  serialize :enabled_in_app_events, coder: YAML

  encrypts :discord_webhook_url

  normalizes :discord_announcement_channel_id, with: ->(value) { value.strip.presence }

  validates :discord_announcement_channel_id, format: {with: ::Discord::ApiClient::SNOWFLAKE_FORMAT}, allow_nil: true

  normalizes :discord_officers_channel_id, with: ->(value) { value.strip.presence }

  validates :discord_officers_channel_id, format: {with: ::Discord::ApiClient::SNOWFLAKE_FORMAT}, allow_nil: true
  DIGEST_TIME_FORMAT = /\A(?:[01]\d|2[0-3]):[0-5]\d\z/

  # Ruby's own numbering, Sunday first, so a weekday compares with `wday`
  # without translation.
  validates :discord_digest_weekday, inclusion: {in: 0..6}, allow_nil: true
  validates :discord_digest_time, format: {with: DIGEST_TIME_FORMAT}, allow_nil: true
  validates :discord_digest_time, presence: true, if: -> { discord_digest_weekday.present? }

  normalizes :discord_digest_time, with: ->(value) { value.strip.presence }

  # A digest found due this long after its slot is not sent: a fleet that
  # switches it on on a Thursday for Mondays is not handed Monday's digest
  # three days late, and neither is one whose scheduler was down.
  DIGEST_GRACE = 1.hour

  # At most one digest in this span, whatever the schedule says: moving the
  # time later on the day it was sent, or a local hour that happens twice when
  # the clocks go back, would otherwise make a second slot the same week.
  DIGEST_MIN_INTERVAL = 6.days

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

  def digest_enabled?
    discord_digest_weekday.present? && discord_digest_time.present?
  end

  # The most recent moment the digest was scheduled for, in the fleet's own
  # timezone, at or before `now`.
  def digest_slot(now = Time.current)
    return nil unless digest_enabled?

    local = now.in_time_zone(fleet.default_timezone.presence || "UTC")
    hour, minute = discord_digest_time.split(":").map(&:to_i)
    slot = (local - ((local.wday - discord_digest_weekday) % 7).days).change(hour: hour, min: minute)
    (slot > local) ? slot - 7.days : slot
  end

  def digest_due?(now = Time.current)
    slot = digest_slot(now)
    return false if slot.nil?
    return false if now - slot > DIGEST_GRACE

    discord_digest_sent_at.nil? || discord_digest_sent_at <= slot - DIGEST_MIN_INTERVAL
  end

  def in_app_enabled?(event_name)
    Array(enabled_in_app_events).include?(event_name)
  end

  private def backfill_discord_member_roles
    return if discord_guild_id.blank?

    ::Discord::BackfillFleetMemberRolesJob.perform_async(fleet_id)
  end
end
