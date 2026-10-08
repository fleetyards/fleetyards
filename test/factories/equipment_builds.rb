FactoryBot.define do
  factory :equipment_build do
    association :equipment, factory: [:equipment, :without_build]
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    sequence(:name) { |n| "#{Faker::Company.name} Rifle #{n}" }
    equipment_type { "weapon" }
    item_type { "assault_rifle" }
    size { "2" }
    hidden { false }
  end
end
