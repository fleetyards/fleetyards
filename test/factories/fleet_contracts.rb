# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_contracts
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("draft"), not null
#  cancelled_at                   :datetime
#  claimed_at                     :datetime
#  cover_image_preset             :string
#  crew_limit                     :integer
#  deadline                       :datetime
#  description                    :text
#  expired_at                     :datetime
#  fulfilled_at                   :datetime
#  kind                           :integer          default("transport"), not null
#  published_at                   :datetime
#  reimburse_expenses             :boolean          default(TRUE), not null
#  reward                         :decimal(15, 2)   default(0.0), not null
#  settled_at                     :datetime
#  slug                           :string           not null
#  title                          :string
#  visibility                     :integer          default("members_only"), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  created_by_id                  :uuid
#  destination_fleet_inventory_id :uuid
#  destination_inventory_id       :uuid
#  fleet_id                       :uuid             not null
#  source_fleet_inventory_id      :uuid
#
# Indexes
#
#  index_fleet_contracts_on_created_by_id                   (created_by_id)
#  index_fleet_contracts_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_fleet_contracts_on_destination_inventory_id        (destination_inventory_id)
#  index_fleet_contracts_on_fleet_id_and_aasm_state         (fleet_id,aasm_state)
#  index_fleet_contracts_on_fleet_id_and_kind               (fleet_id,kind)
#  index_fleet_contracts_on_fleet_id_and_slug               (fleet_id,slug) UNIQUE
#  index_fleet_contracts_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (destination_inventory_id => inventories.id) ON DELETE => nullify
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :fleet_contract do
    fleet
    association :created_by, factory: :user
    sequence(:title) { |n| "Contract #{n}" }
    description { Faker::Lorem.sentence }
    kind { :procurement }
    reward { 120_000 }

    destination_fleet_inventory do
      association(:fleet_inventory, fleet: fleet)
    end

    # Delivered into the author's own inventory rather than one of the fleet's.
    trait :hangar_destination do
      destination_fleet_inventory { nil }
      destination_inventory do
        association(:inventory, holder: created_by)
      end
    end

    trait :transport do
      kind { :transport }
      source_fleet_inventory do
        association(:fleet_inventory, fleet: fleet)
      end
    end

    trait :crafting do
      kind { :crafting }
    end

    trait :with_item do
      after(:create) do |contract|
        create(:fleet_contract_item, fleet_contract: contract)
      end
    end

    trait :published do
      with_item
      aasm_state { "open" }
      published_at { Time.current }
    end

    trait :in_progress do
      with_item
      aasm_state { "in_progress" }
      published_at { Time.current }
      claimed_at { Time.current }
    end

    trait :fulfilled do
      in_progress
      aasm_state { "fulfilled" }
      fulfilled_at { Time.current }
    end
  end
end
