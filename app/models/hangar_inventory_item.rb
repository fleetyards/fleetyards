# frozen_string_literal: true

# == Schema Information
#
# Table name: hangar_inventory_items
#
#  id                  :uuid             not null, primary key
#  category            :integer          default(0), not null
#  entry_type          :integer          default(0), not null
#  item_type           :string
#  name                :string           not null
#  notes               :text
#  quality             :integer          default(0)
#  quantity            :decimal(15, 2)   default(0.0), not null
#  unit                :integer          default(0), not null
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
class HangarInventoryItem < ApplicationRecord
  include InventoryLedgerEntry

  has_paper_trail

  paginates_per 30

  inventory_association :hangar_inventory

  def self.ransackable_attributes(_auth_object = nil)
    %w[name category unit entry_type quality hangar_inventory_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[hangar_inventory item]
  end
end
