# frozen_string_literal: true

# One material a slot accepts. Every slot in 4.10.1 accepts exactly one, but the
# game files allow several and the UI already has the string for it.
# == Schema Information
#
# Table name: blueprint_cost_options
#
#  id                     :uuid             not null, primary key
#  commodity_key          :string
#  cost_type              :string           not null
#  min_quality            :integer
#  position               :integer          not null
#  quantity               :decimal(12, 4)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  blueprint_cost_slot_id :uuid             not null
#  commodity_id           :uuid
#
# Indexes
#
#  index_blueprint_cost_options_on_commodity_id       (commodity_id)
#  index_blueprint_cost_options_on_slot               (blueprint_cost_slot_id)
#  index_blueprint_cost_options_on_slot_and_position  (blueprint_cost_slot_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_cost_slot_id => blueprint_cost_slots.id) ON DELETE => cascade
#  fk_rails_...  (commodity_id => commodities.id) ON DELETE => nullify
#
class BlueprintCostOption < ApplicationRecord
  belongs_to :slot,
    class_name: "BlueprintCostSlot", inverse_of: :options,
    foreign_key: :blueprint_cost_slot_id

  # Nullable: a material the commodity catalogue has no row for must not take
  # the recipe down with it, and `commodity_key` still says which one it is.
  belongs_to :commodity, optional: true

  # Also the unit. A resource is measured in SCU, an item in whole pieces.
  TYPES = %w[resource item].freeze

  validates :cost_type, presence: true, inclusion: {in: TYPES}
  validates :position, presence: true, uniqueness: {scope: :blueprint_cost_slot_id}
end
