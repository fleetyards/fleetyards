# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_notification_settings
#
#  id                              :uuid             not null, primary key
#  discord_digest_sent_at          :datetime
#  discord_digest_time             :string
#  discord_digest_timezone         :string
#  discord_digest_weekday          :integer
#  discord_webhook_url             :text
#  enabled_in_app_events           :text             default(["fleet_event.published", "fleet_event.locked", "fleet_event.starting_soon", "fleet_event.cancelled", "fleet_event_signup.created", "fleet_event_signup.withdrawn"])
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  discord_announcement_channel_id :string
#  discord_channel_id              :string
#  discord_guild_id                :string
#  discord_join_role_id            :string
#  discord_join_role_swept_at      :datetime
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

  DISCORD_ID_ATTRIBUTES = %i[
    discord_guild_id
    discord_channel_id
    discord_member_role_id
    discord_join_role_id
    discord_announcement_channel_id
    discord_officers_channel_id
  ].freeze

  # Each one is interpolated into a Discord API path, so a server's name typed
  # where its id belongs would not even make a valid URL.
  normalizes(*DISCORD_ID_ATTRIBUTES, with: ->(value) { value.strip.presence })

  validates(*DISCORD_ID_ATTRIBUTES, format: {with: ::Discord::ApiClient::SNOWFLAKE_FORMAT, message: :not_a_discord_id}, allow_nil: true)

  # @everyone has the guild's own id and every member holds it, so as the join
  # role it would let the whole server in without a request.
  validate do
    errors.add(:discord_join_role_id, :everyone_role) if discord_join_role_id.present? && discord_join_role_id == discord_guild_id
  end

  DIGEST_TIME_FORMAT = /\A(?:[01]\d|2[0-3]):[0-5]\d\z/

  # Ruby's own numbering, Sunday first, so a weekday compares with `wday`
  # without translation.
  validates :discord_digest_weekday, inclusion: {in: 0..6}, allow_nil: true
  validates :discord_digest_time, format: {with: DIGEST_TIME_FORMAT}, allow_nil: true
  validates :discord_digest_time, presence: true, if: -> { discord_digest_weekday.present? }

  normalizes :discord_digest_time, with: ->(value) { value.strip.presence }

  # The zone the day and time were picked in. Stored with them rather than
  # read off the fleet, whose own default nobody can set.
  validates :discord_digest_timezone, inclusion: {in: ->(_) { TZInfo::Timezone.all_identifiers }}, allow_nil: true

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
  # Every other id, each rank's role and each squadron's channel names a
  # channel or role in one guild, so another guild leaves them pointing at
  # nothing -- and switching back must not bring them back either: the join
  # role would let everyone holding it in without the invite privilege it
  # needs. Ids saved along with the new guild are its own.
  before_save :clear_guild_scoped_ids, if: :discord_guild_id_changed?
  after_save :clear_guild_scoped_records, if: :saved_change_to_discord_guild_id?
  # Until a new join role's first sweep has read the whole guild, holding it
  # is not gaining it, so nothing brings back a member whose membership ended.
  # Who held the previous role says nothing about the new one, so the sweep
  # applies the new one as gained by everyone holding it and lost by nobody:
  # changing the role keeps the members the old one brought in.
  before_save -> { self.discord_join_role_swept_at = nil }, if: :discord_join_role_id_changed?
  # Nor does when someone was last read for it.
  after_save -> {
    FleetDiscordRoleHolder.where(fleet_id:).delete_all
    DiscordMemberRead.where(fleet_id:).delete_all
  }, if: :saved_change_to_discord_join_role_id?
  after_commit :sync_discord_join_role, if: :saved_change_to_discord_join_role_id?

  scope :with_join_role, -> { where.not(discord_join_role_id: nil).where.not(discord_guild_id: nil) }

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

  # The most recent moment the digest was scheduled for, in the zone it was
  # set up in, at or before `now`.
  def digest_slot(now = Time.current)
    return nil unless digest_enabled?

    local = now.in_time_zone(discord_digest_timezone.presence || "UTC")
    hour, minute = discord_digest_time.split(":").map(&:to_i)
    slot = (local - ((local.wday - discord_digest_weekday) % 7).days).change(hour: hour, min: minute)
    (slot > local) ? slot - 7.days : slot
  end

  # Whether a claim made at `claimed_at` still answers the schedule as it is
  # now. Moved to another day or time after the claim, it does not, and the
  # digest belongs to the new slot instead.
  def digest_claim_current?(claimed_at)
    slot = digest_slot(claimed_at)

    slot.present? && claimed_at - slot <= DIGEST_GRACE
  end

  # Whether a digest claimed at `claimed_at` may still go out at `now`: it is
  # still the week's claim, the schedule still points at it, and it is not
  # later than a digest found due would be sent at all.
  def digest_claim_live?(claimed_at, now = Time.current)
    digest_enabled? &&
      discord_digest_sent_at == claimed_at &&
      digest_claim_current?(claimed_at) &&
      now - digest_slot(claimed_at) <= DIGEST_GRACE
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

  private def clear_guild_scoped_ids
    (DISCORD_ID_ATTRIBUTES - [:discord_guild_id]).each do |attribute|
      self[attribute] = nil unless attribute_changed?(attribute)
    end
  end

  private def clear_guild_scoped_records
    FleetRole.where(fleet_id:).where.not(discord_role_id: nil).update_all(discord_role_id: nil, updated_at: Time.current)
    FleetSquadron.where(fleet_id:).where.not(discord_channel_id: nil).update_all(discord_channel_id: nil, updated_at: Time.current)
  end

  private def sync_discord_join_role
    ::Discord::SyncFleetJoinRoleJob.perform_async(fleet_id)
  end

  private def backfill_discord_member_roles
    return if discord_guild_id.blank?

    ::Discord::BackfillFleetMemberRolesJob.perform_async(fleet_id)
  end
end
