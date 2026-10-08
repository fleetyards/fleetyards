FactoryBot.define do
  factory :component_build do
    association :component, factory: [:component, :without_build]
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    sequence(:name) { |n| "#{Faker::Company.name} Shield #{n}" }
    size { "2" }
    grade { "A" }
    hidden { false }
  end
end
