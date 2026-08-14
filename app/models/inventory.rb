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
#  vehicle_id  :uuid
#
# Indexes
#
#  index_inventories_on_holder_and_lower_name               (holder_type, holder_id, lower((name)::text)) UNIQUE WHERE (vehicle_id IS NULL)
#  index_inventories_on_holder_type_and_holder_id           (holder_type,holder_id)
#  index_inventories_on_holder_type_and_holder_id_and_slug  (holder_type,holder_id,slug) UNIQUE WHERE (vehicle_id IS NULL)
#  index_inventories_on_vehicle_id                          (vehicle_id) UNIQUE WHERE (vehicle_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id) ON DELETE => nullify
#
class Inventory < ApplicationRecord
  include ActiveStorageVariants
  include InventoryStock

  has_paper_trail

  paginates_per 30

  belongs_to :holder, polymorphic: true, touch: true
  belongs_to :vehicle, optional: true

  inventory_items_association :inventory_items

  has_one_attached :image

  # Slugs are unique among these only. Two Ironclads produce the same slug, so a
  # ship inventory is addressed through its ship instead.
  scope :addressable_by_slug, -> { where(vehicle_id: nil) }

  validates :name, presence: true
  validates :name, uniqueness: {case_sensitive: false, scope: [:holder_type, :holder_id]},
    unless: :vehicle_id?

  # A ship inventory comes into existence with its first deposit, named after the
  # ship it rides in.
  def self.provision_for(vehicle, holder:)
    find_by(holder:, vehicle:) || create_for(vehicle, holder:)
  end

  # Two first deposits racing are settled by the unique index on `vehicle_id`.
  # The savepoint keeps the loser's surrounding transaction usable so it can pick
  # up the row the winner just wrote.
  def self.create_for(vehicle, holder:)
    transaction(requires_new: true) do
      create!(holder:, vehicle:, name: vehicle.default_inventory_name)
    end
  rescue ActiveRecord::RecordNotUnique
    find_by!(holder:, vehicle:)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug vehicle_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def vehicle?
    vehicle_id.present?
  end
end
