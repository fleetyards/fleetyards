# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_slots
#
#  id                :uuid             not null, primary key
#  description       :text
#  position          :integer          default(0), not null
#  signup_approval   :string
#  slottable_type    :string           not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  model_position_id :uuid
#  slottable_id      :uuid             not null
#  source_slot_id    :uuid
#
# Indexes
#
#  index_fleet_event_slots_on_model_position_id                (model_position_id)
#  index_fleet_event_slots_on_slottable_and_position           (slottable_type,slottable_id,position)
#  index_fleet_event_slots_on_slottable_type_and_slottable_id  (slottable_type,slottable_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_position_id => model_positions.id)
#  fk_rails_...  (source_slot_id => mission_slots.id) ON DELETE => nullify
#
class FleetEventSlot < ApplicationRecord
  belongs_to :slottable, polymorphic: true, touch: true
  belongs_to :model_position, optional: true
  belongs_to :source_slot, class_name: "MissionSlot", optional: true
  has_many :fleet_event_signups, dependent: :destroy

  validates :title, presence: true
  validates :slottable_type, inclusion: {in: %w[FleetEventTeam FleetEventShip]}
  validates :signup_approval,
    inclusion: {in: FleetEvent::SIGNUP_APPROVALS},
    allow_nil: true

  default_scope -> { order(position: :asc) }

  def fleet_event
    case slottable
    when FleetEventTeam
      slottable.fleet_event
    when FleetEventShip
      slottable.fleet_event_team.fleet_event
    end
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
