# frozen_string_literal: true

# What filling a slot with better material buys: one stat, ramped over material
# quality 0 to 1000.
#
# A stat can carry several rows for one slot. 1007 of the slots in 4.10.1 ramp a
# stat piecewise -- 0.95 to 1.0 across quality 0-499, then 1.0 to 1.05 across
# 500-1000 -- so the range a page shows spans the segments rather than reading
# one of them.
# == Schema Information
#
# Table name: blueprint_cost_modifiers
#
#  id                     :uuid             not null, primary key
#  end_quality            :integer
#  modifier_at_end        :decimal(12, 4)
#  modifier_at_start      :decimal(12, 4)
#  name                   :string
#  position               :integer          not null
#  property_key           :string
#  property_ref           :string
#  ramp                   :string           not null
#  start_quality          :integer
#  unit_format            :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  blueprint_cost_slot_id :uuid             not null
#
# Indexes
#
#  index_blueprint_cost_modifiers_on_slot               (blueprint_cost_slot_id)
#  index_blueprint_cost_modifiers_on_slot_and_position  (blueprint_cost_slot_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_cost_slot_id => blueprint_cost_slots.id) ON DELETE => cascade
#
class BlueprintCostModifier < ApplicationRecord
  belongs_to :slot,
    class_name: "BlueprintCostSlot", inverse_of: :modifiers,
    foreign_key: :blueprint_cost_slot_id

  # `linear` scales the stat, `linear_integer_additive` adds to it.
  RAMPS = %w[linear linear_integer_additive].freeze

  validates :ramp, presence: true, inclusion: {in: RAMPS}
  validates :position, presence: true, uniqueness: {scope: :blueprint_cost_slot_id}

  # The game carries the stat's unit inside a printf format -- "%+.2f ºC",
  # "%.2f RPM", "%+.2f %%" -- which is how it renders the figure rather than
  # something a page can print. Only the unit is wanted here; the sign and the
  # precision are the game's presentation, not ours.
  UNIT_FORMAT = /%[-+ 0#]*[\d.]*[a-z]/

  def unit
    return if unit_format.blank?
    # "Rating" and the like name the stat instead of formatting a number.
    return unless unit_format.match?(UNIT_FORMAT)

    unit_format.sub(UNIT_FORMAT, "").gsub("%%", "%").strip.presence
  end
end
