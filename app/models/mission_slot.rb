# frozen_string_literal: true

class MissionSlot < ApplicationRecord
  belongs_to :slottable, polymorphic: true, touch: true
  belongs_to :model_position, optional: true

  validates :title, presence: true
  validates :slottable_type, inclusion: {in: %w[MissionTeam MissionShip]}

  default_scope -> { order(position: :asc) }

  def mission
    slottable&.mission
  end

  def derived?
    model_position_id.present?
  end

  def position_type
    model_position&.position_type
  end
end
