# frozen_string_literal: true

FactoryBot.define do
  factory :equipment_attachment do
    build { association :equipment_build }
    attachment { association :equipment, equipment_type: "weapon_attachment", sub_type: "Magazine", size: "1" }
    port_name { "magazine_attach" }
    port_type { "Magazine" }
    default { false }
  end
end
