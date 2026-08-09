# frozen_string_literal: true

# == Schema Information
#
# Table name: hangar_inventory_items
#
#  id                  :uuid             not null, primary key
#  category            :integer          default("commodity"), not null
#  entry_type          :integer          default("deposit"), not null
#  item_type           :string
#  name                :string           not null
#  notes               :text
#  quality             :integer          default(0)
#  quantity            :decimal(15, 2)   default(0.0), not null
#  unit                :integer          default("scu"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  hangar_inventory_id :uuid             not null
#  item_id             :uuid
#
# Indexes
#
#  index_hangar_inventory_items_on_hangar_inventory_id  (hangar_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (hangar_inventory_id => hangar_inventories.id)
#
FactoryBot.define do
  factory :hangar_inventory_item do
    hangar_inventory
    name { Faker::Commerce.product_name }
    category { :commodity }
    quantity { rand(1..100) }
    unit { :scu }

    trait :with_notes do
      notes { Faker::Lorem.sentence }
    end

    trait :component do
      category { :component }
      unit { :units }
    end

    trait :withdrawal do
      entry_type { :withdrawal }
    end
  end
end
