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
#  visibility  :integer          default("members_only"), not null
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

  paginates_per 30

  belongs_to :fleet, touch: true
  belongs_to :manager, class_name: "User", foreign_key: :managed_by, optional: true
  has_many :fleet_inventory_items, dependent: :destroy

  has_one_attached :image

  enum :visibility, {members_only: 0, officers_only: 1}

  validates :name, presence: true, uniqueness: {case_sensitive: false, scope: :fleet_id}

  before_save :update_slugs

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

  DEFAULT_SORTING_PARAMS = ["name asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug fleet_id visibility created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet manager]
  end

  def current_stock
    fleet_inventory_items
      .select(
        "name, category, unit, quality",
        "SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) AS net_quantity"
      )
      .group(:name, :category, :unit, :quality)
      .having("SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) > 0")
      .order(:name)
  end

  private def update_slugs
    self.slug = generate_slug(name)
  end
end
