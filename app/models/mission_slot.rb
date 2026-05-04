# frozen_string_literal: true

# == Schema Information
#
# Table name: mission_slots
#
#  id                :uuid             not null, primary key
#  description       :text
#  position          :integer          default(0), not null
#  slottable_type    :string           not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  model_position_id :uuid
#  slottable_id      :uuid             not null
#
# Indexes
#
#  index_mission_slots_on_model_position_id                (model_position_id)
#  index_mission_slots_on_slottable_and_position           (slottable_type,slottable_id,position)
#  index_mission_slots_on_slottable_type_and_slottable_id  (slottable_type,slottable_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_position_id => model_positions.id)
#
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
