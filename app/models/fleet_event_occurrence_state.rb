# frozen_string_literal: true

# Per-occurrence overlay row for recurring FleetEvents. Each row tracks
# state that differs per-occurrence: lifecycle timestamps, Discord scheduled
# event linkage, and any per-occurrence override fields (title, location,
# scenario, etc). nil columns mean "inherit from the parent FleetEvent".
# == Schema Information
#
# Table name: fleet_event_occurrence_states
#
#  id                        :uuid             not null, primary key
#  briefing                  :text
#  cancelled_at              :datetime
#  cancelled_reason          :text
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  location                  :string
#  locked_at                 :datetime
#  meetup_location           :string
#  occurrence_date           :date             not null
#  scenario                  :string
#  starting_soon_notified_at :datetime
#  status                    :string
#  title                     :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  discord_event_id          :string
#  fleet_event_id            :uuid             not null
#
# Indexes
#
#  idx_fleet_event_occurrence_states_on_event_and_date  (fleet_event_id,occurrence_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#
class FleetEventOccurrenceState < ApplicationRecord
  belongs_to :fleet_event, touch: true

  validates :occurrence_date, presence: true
  validates :fleet_event_id, uniqueness: {scope: :occurrence_date}

  STATUSES = FleetEvent::STATUSES if defined?(FleetEvent::STATUSES)

  def cancelled?
    cancelled_at.present? || status == "cancelled"
  end

  def locked?
    locked_at.present?
  end

  def starting_soon_notified?
    starting_soon_notified_at.present?
  end

  # Field accessor that prefers the override, falling back to the event's
  # value. Used by serialisers and Discord/ICS builders.
  def effective(attr)
    public_send(attr).presence || fleet_event.public_send(attr)
  end
end
