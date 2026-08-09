# frozen_string_literal: true

# == Schema Information
#
# Table name: hangar_inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null
#
# Indexes
#
#  index_hangar_inventories_on_user_id_and_lower_name  (user_id, lower((name)::text)) UNIQUE
#  index_hangar_inventories_on_user_id_and_slug        (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class HangarInventory < ApplicationRecord
  include ActiveStorageVariants
  include InventoryStock

  has_paper_trail

  paginates_per 30

  belongs_to :user, touch: true

  inventory_items_association :hangar_inventory_items

  has_one_attached :image

  validates :name, presence: true, uniqueness: {case_sensitive: false, scope: :user_id}

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug user_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
