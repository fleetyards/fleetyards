# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_contract_items
#
#  id                :uuid             not null, primary key
#  category          :integer          default(0), not null
#  item_type         :string
#  min_quality       :integer
#  name              :string           not null
#  position          :integer          default(0), not null
#  quantity          :decimal(15, 2)   default(0.0), not null
#  unit              :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_contract_id :uuid             not null
#  item_id           :uuid
#
# Indexes
#
#  index_fleet_contract_items_on_fleet_contract_id               (fleet_contract_id)
#  index_fleet_contract_items_on_fleet_contract_id_and_position  (fleet_contract_id,position)
#  index_fleet_contract_items_on_identity                        (fleet_contract_id, lower((name)::text), category, unit) UNIQUE
#  index_fleet_contract_items_on_item_type_and_item_id           (item_type,item_id)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_contract_id => fleet_contracts.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :fleet_contract_item do
    fleet_contract
    name { Faker::Commerce.product_name }
    category { :commodity }
    unit { :scu }
    quantity { 100 }

    trait :component do
      category { :component }
      unit { :units }
    end

    trait :graded do
      min_quality { 500 }
    end
  end
end
