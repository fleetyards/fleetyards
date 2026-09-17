# frozen_string_literal: true

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
