# frozen_string_literal: true

# == Schema Information
#
# Table name: inventory_positions
#
#  id           :uuid             not null, primary key
#  category     :integer          default(0), not null
#  name         :string           not null
#  slug         :string           not null
#  unit         :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inventory_id :uuid             not null
#
# Indexes
#
#  index_inventory_positions_on_inventory_and_identity  (inventory_id,name,category,unit) UNIQUE
#  index_inventory_positions_on_inventory_and_slug      (inventory_id,slug) UNIQUE
#  index_inventory_positions_on_inventory_id            (inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_id => inventories.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :inventory_position do
    inventory
    name { Faker::Commerce.product_name }
    category { :commodity }
    unit { :scu }

    trait :component do
      category { :component }
      unit { :units }
    end
  end
end
