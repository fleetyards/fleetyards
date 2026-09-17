# frozen_string_literal: true

# One named aspect of a recipe -- "Frame", "Wiring", "Armored Carapace" -- with
# the materials that can fill it and the stats filling it moves.
#
# The blueprint's `slot_count` says how many of these a single craft fills,
# which is not always all of them.
# == Schema Information
#
# Table name: blueprint_cost_slots
#
#  id           :uuid             not null, primary key
#  name         :string
#  position     :integer          not null
#  sc_key       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  blueprint_id :uuid             not null
#
# Indexes
#
#  index_blueprint_cost_slots_on_blueprint_id               (blueprint_id)
#  index_blueprint_cost_slots_on_blueprint_id_and_position  (blueprint_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_id => blueprints.id) ON DELETE => cascade
#
class BlueprintCostSlot < ApplicationRecord
  belongs_to :blueprint

  has_many :options,
    -> { order(:position) },
    class_name: "BlueprintCostOption", inverse_of: :slot,
    foreign_key: :blueprint_cost_slot_id, dependent: :destroy

  has_many :modifiers,
    -> { order(:position) },
    class_name: "BlueprintCostModifier", inverse_of: :slot,
    foreign_key: :blueprint_cost_slot_id, dependent: :destroy

  validates :position, presence: true, uniqueness: {scope: :blueprint_id}
end
