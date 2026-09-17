# frozen_string_literal: true

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
FactoryBot.define do
  factory :blueprint_cost_modifier do
    slot factory: :blueprint_cost_slot
    property_ref { Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "gpp") }
    property_key { "gpp_weapon_damage" }
    name { "Impact Force" }
    unit_format { "%+.2f %%" }
    ramp { "linear" }
    start_quality { 0 }
    end_quality { 1000 }
    modifier_at_start { 0.95 }
    modifier_at_end { 1.05 }
    position { 0 }

    trait :additive do
      ramp { "linear_integer_additive" }
    end
  end
end
