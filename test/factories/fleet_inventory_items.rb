# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventory_items
#
#  id                 :uuid             not null, primary key
#  added_by           :uuid
#  category           :integer          default("commodity"), not null
#  entry_type         :integer          default("deposit"), not null
#  item_type          :string
#  name               :string           not null
#  notes              :text
#  quality            :integer          default(0)
#  quantity           :decimal(15, 2)   default(0.0), not null
#  unit               :integer          default("scu"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  fleet_inventory_id :uuid             not null
#  item_id            :uuid
#  member_id          :uuid
#
# Indexes
#
#  index_fleet_inventory_items_on_fleet_inventory_id  (fleet_inventory_id)
#  index_fleet_inventory_items_on_member_id           (member_id)
#
# Foreign Keys
#
#  fk_rails_...  (added_by => users.id)
#  fk_rails_...  (fleet_inventory_id => fleet_inventories.id)
#  fk_rails_...  (member_id => users.id)
#
FactoryBot.define do
  factory :fleet_inventory_item do
    fleet_inventory
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

    trait :ship do
      category { :ship }
      unit { :units }
    end
  end
end
