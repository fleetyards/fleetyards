# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  location    :string
#  managed_by  :uuid
#  name        :string           not null
#  slug        :string           not null
#  visibility  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  fleet_id    :uuid             not null
#
# Indexes
#
#  index_fleet_inventories_on_fleet_id_and_lower_name  (fleet_id, lower((name)::text)) UNIQUE
#  index_fleet_inventories_on_fleet_id_and_managed_by  (fleet_id,managed_by)
#  index_fleet_inventories_on_fleet_id_and_slug        (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (managed_by => users.id)
#
class FleetInventory < ApplicationRecord
  include ActiveStorageVariants
  include InventoryStock

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  belongs_to :fleet, touch: true
  belongs_to :manager, class_name: "User", foreign_key: :managed_by, optional: true

  inventory_items_association :fleet_inventory_items

  has_one_attached :image
  validates :image, no_vector_image: true

  enum :visibility, {members_only: 0, officers_only: 1}

  validates :name, presence: true, uniqueness: {case_sensitive: false, scope: :fleet_id}

  AVAILABLE_PRIVILEGES = [
    "fleet:inventories:read",
    "fleet:inventories:create",
    "fleet:inventories:update",
    "fleet:inventories:delete",
    "fleet:inventories:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:inventories:manage"],
    member: ["fleet:inventories:read"]
  }.freeze

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug fleet_id visibility created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet manager]
  end

  def ledger_attributes_for(user)
    {added_by: user&.id}
  end
end
