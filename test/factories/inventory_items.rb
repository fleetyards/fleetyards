# frozen_string_literal: true

# == Schema Information
#
# Table name: inventory_items
#
#  id           :uuid             not null, primary key
#  category     :integer          default(0), not null
#  entry_type   :integer          default(0), not null
#  item_type    :string
#  name         :string           not null
#  notes        :text
#  quality      :integer          default(0)
#  quantity     :decimal(15, 2)   default(0.0), not null
#  unit         :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inventory_id :uuid             not null
#  item_id      :uuid
#
# Indexes
#
#  index_inventory_items_on_inventory_id  (inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_id => inventories.id)
#
FactoryBot.define do
  factory :inventory_item do
    inventory
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
  end
end
