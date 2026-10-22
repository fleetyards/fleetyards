FactoryBot.define do
  factory :buyback_pledge do
    user
    kind { "ship" }
    sequence(:rsi_pledge_id) { |n| (20_000_000 + n).to_s }
    name { "Standalone Ship - Cutlass Black" }
    price { 110 }
  end
end
