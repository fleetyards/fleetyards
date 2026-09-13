# frozen_string_literal: true

# == Schema Information
#
# Table name: inventory_transfers
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("pending"), not null
#  cancelled_at                   :datetime
#  completed_at                   :datetime
#  declined_at                    :datetime
#  expired_at                     :datetime
#  expires_at                     :datetime
#  note                           :text
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  destination_fleet_inventory_id :uuid
#  destination_inventory_id       :uuid
#  initiated_by_id                :uuid
#  recipient_fleet_id             :uuid
#  recipient_id                   :uuid
#  resolved_by_id                 :uuid
#  source_fleet_inventory_id      :uuid
#  source_inventory_id            :uuid
#
# Indexes
#
#  index_inventory_transfers_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_inventory_transfers_on_destination_inventory_id        (destination_inventory_id)
#  index_inventory_transfers_on_initiated_by_id                 (initiated_by_id)
#  index_inventory_transfers_on_pending_expires_at              (expires_at) WHERE ((aasm_state)::text = 'pending'::text)
#  index_inventory_transfers_on_pending_recipient               (recipient_id) WHERE ((aasm_state)::text = 'pending'::text)
#  index_inventory_transfers_on_pending_recipient_fleet         (recipient_fleet_id) WHERE ((aasm_state)::text = 'pending'::text)
#  index_inventory_transfers_on_recipient_fleet_id              (recipient_fleet_id)
#  index_inventory_transfers_on_recipient_id                    (recipient_id)
#  index_inventory_transfers_on_resolved_by_id                  (resolved_by_id)
#  index_inventory_transfers_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#  index_inventory_transfers_on_source_inventory_id             (source_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (destination_inventory_id => inventories.id) ON DELETE => nullify
#  fk_rails_...  (initiated_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (recipient_fleet_id => fleets.id) ON DELETE => nullify
#  fk_rails_...  (recipient_id => users.id) ON DELETE => nullify
#  fk_rails_...  (resolved_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (source_inventory_id => inventories.id) ON DELETE => nullify
#
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
