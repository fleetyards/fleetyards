# frozen_string_literal: true

# == Schema Information
#
# Table name: inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  holder_type :string           not null
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  holder_id   :uuid             not null
#
# Indexes
#
#  index_inventories_on_holder_and_lower_name               (holder_type, holder_id, lower((name)::text)) UNIQUE
#  index_inventories_on_holder_type_and_holder_id           (holder_type,holder_id)
#  index_inventories_on_holder_type_and_holder_id_and_slug  (holder_type,holder_id,slug) UNIQUE
#
class Inventory < ApplicationRecord
  include ActiveStorageVariants
  include InventoryStock

  has_paper_trail

  paginates_per 30

  belongs_to :holder, polymorphic: true, touch: true

  inventory_items_association :inventory_items

  has_one_attached :image

  validates :name, presence: true, uniqueness: {case_sensitive: false, scope: [:holder_type, :holder_id]}

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
