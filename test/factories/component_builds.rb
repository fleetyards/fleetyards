FactoryBot.define do
  factory :component_build do
    component
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    sequence(:name) { |n| "#{Faker::Company.name} Shield #{n}" }
    component_class { "Shield" }
    item_type { "Shield" }
    size { "2" }
    grade { "A" }
    hidden { false }
  end
end
