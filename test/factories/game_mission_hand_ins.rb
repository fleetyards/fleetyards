# frozen_string_literal: true

FactoryBot.define do
  factory :game_mission_hand_in do
    build factory: :game_mission_build
    kind { "item" }
    ref { Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "hand-in") }
    name { "Yormandi Eye" }
    amount { 14 }
    sequence(:position) { |n| n }

    trait :resource do
      kind { "resource" }
      name { "Quartz" }
      amount { 2 }
    end
  end
end
