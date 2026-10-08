# frozen_string_literal: true

# One named aspect of a recipe -- "Frame", "Wiring", "Armored Carapace" -- with
# the materials that can fill it and the stats filling it moves.
#
# The blueprint's `slot_count` says how many of these a single craft fills,
# which is not always all of them.
#
# Hung off the build rather than the blueprint: a recipe is a fact of one build,
# and live and ptu each have to keep their own.
class BlueprintCostSlot < ApplicationRecord
  belongs_to :build, class_name: "BlueprintBuild", inverse_of: :cost_slots,
    foreign_key: :blueprint_build_id

  has_many :options,
    -> { order(:position) },
    class_name: "BlueprintCostOption", inverse_of: :slot,
    foreign_key: :blueprint_cost_slot_id, dependent: :destroy

  has_many :modifiers,
    -> { order(:position) },
    class_name: "BlueprintCostModifier", inverse_of: :slot,
    foreign_key: :blueprint_cost_slot_id, dependent: :destroy

  validates :position, presence: true, uniqueness: {scope: :blueprint_build_id}
end
