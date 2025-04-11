FactoryBot.define do
  factory :model_hardpoint do
    source { ModelHardpoint.sources.keys.sample }
    key { Faker::Alphanumeric.alphanumeric(number: 10) }
    hardpoint_type { ModelHardpoint.hardpoint_types.keys.sample }
    group { ModelHardpoint.groups.keys.sample }
    model
  end
end
