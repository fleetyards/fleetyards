# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_transfer do
    association :source_inventory, factory: :inventory
    association :initiated_by, factory: :user

    # A transfer needs a target, and the two shapes are mutually exclusive: an
    # immediate one names an inventory, a pending one names a party.
    trait :to_inventory do
      association :destination_inventory, factory: :inventory
    end

    trait :to_user do
      association :recipient, factory: :user
      expires_at { InventoryTransfer::DEFAULT_TTL.from_now }
    end

    trait :to_fleet do
      association :recipient_fleet, factory: :fleet
      expires_at { InventoryTransfer::DEFAULT_TTL.from_now }
    end

    trait :from_fleet do
      source_inventory { nil }
      association :source_fleet_inventory, factory: :fleet_inventory
    end

    trait :completed do
      aasm_state { "completed" }
      completed_at { Time.zone.now }
    end

    trait :expired_ttl do
      expires_at { 1.day.ago }
    end
  end
end
