# frozen_string_literal: true

class FleetEventSlot < ApplicationRecord
  include SlotRole

  belongs_to :slottable, polymorphic: true, touch: true
  belongs_to :model_position, optional: true
  belongs_to :source_slot, class_name: "MissionSlot", optional: true
  has_many :fleet_event_signups, dependent: :destroy
  has_many :fleet_event_slot_candidates, dependent: :destroy

  attr_readonly :lead

  validates :title, presence: true
  validates :slottable_type, inclusion: {in: %w[FleetEventTeam FleetEventShip]}
  validates :signup_approval,
    inclusion: {in: FleetEvent::SIGNUP_APPROVALS},
    allow_nil: true

  def fleet_event
    case slottable
    when FleetEventTeam
      slottable.fleet_event
    when FleetEventShip
      slottable.fleet_event_team.fleet_event
    end
  end

  # The lead seat's name is the app's, in the reader's language; the stored
  # title is only the fallback for a reader with none.
  def display_title
    lead? ? I18n.t("labels.slots.lead", default: title) : title
  end

  def derived?
    model_position_id.present?
  end

  def position_type
    model_position&.position_type
  end

  def active_signups
    fleet_event_signups.where.not(status: "withdrawn")
  end
end
