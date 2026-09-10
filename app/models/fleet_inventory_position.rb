# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventory_positions
#
#  id                 :uuid             not null, primary key
#  category           :integer          default(0), not null
#  name               :string           not null
#  slug               :string           not null
#  unit               :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  fleet_inventory_id :uuid             not null
#
# Indexes
#
#  index_fleet_inventory_positions_on_fleet_inventory_id      (fleet_inventory_id)
#  index_fleet_inventory_positions_on_inventory_and_identity  (fleet_inventory_id,name,category,unit) UNIQUE
#  index_fleet_inventory_positions_on_inventory_and_slug      (fleet_inventory_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_inventory_id => fleet_inventories.id) ON DELETE => cascade
#
class FleetInventoryPosition < ApplicationRecord
  include StockPosition

  inventory_association :fleet_inventory

  has_many :fleet_inventory_items, dependent: :restrict_with_error
end
