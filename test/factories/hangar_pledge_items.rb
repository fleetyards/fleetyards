FactoryBot.define do
  factory :hangar_pledge_item do
    kind { "paint" }
    sequence(:rsi_pledge_id) { |n| (10_000_000 + n).to_s }
    name { "Cutlass - Akuma Paint" }

    association :user
  end
end
