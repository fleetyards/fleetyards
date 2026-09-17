# frozen_string_literal: true

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
FactoryBot.define do
  factory :blueprint_cost_option do
    slot factory: :blueprint_cost_slot
    commodity
    commodity_key { "items_commodities_iron" }
    cost_type { "resource" }
    quantity { 0.03 }
    min_quality { 0 }
    position { 0 }

    trait :item do
      cost_type { "item" }
      quantity { 2 }
    end
  end
end
