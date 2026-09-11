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

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  belongs_to :holder, polymorphic: true, touch: true
  belongs_to :vehicle, optional: true

  inventory_items_association :inventory_items
  positions_association :inventory_positions

  has_one_attached :image
  validates :image, no_vector_image: true

  # The inventories a user created by hand, as opposed to the ones a ship
  # provisioned for itself.
  scope :hand_made, -> { where(vehicle_id: nil) }

  # Slugs are unique among these only. Two Ironclads produce the same slug, so a
  # ship inventory is addressed through its ship instead.
  scope :addressable_by_slug, -> { hand_made }

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

  # Losing the ship puts this row into the two unique indexes that only cover
  # `vehicle_id IS NULL`, on `lower(name)` and on `slug`. A ship inventory is
  # named after its ship, so a user with two of the same model holds two rows
  # with the same name and the second one to be detached collides. Postgres does
  # the detaching itself, through `on_delete: :nullify`, so nothing on that path
  # validates anything -- the name has to be free before the ship goes.
  #
  # Free among every other inventory of this holder rather than among the
  # hand-made ones: the sibling detached in the same breath is still holding its
  # `vehicle_id` while this runs, and would be invisible to the narrower check.
  # Locked and ordered by id, including this row: two of the holder's
  # inventories detaching at once would otherwise each read the other still
  # holding its `vehicle_id`, pick the same suffix, and collide when Postgres
  # nullifies them. Taking the row being excluded as well is what keeps the two
  # from locking each other's row first and deadlocking.
  # The label the ship leaves behind. `update_column` rather than `update` for the
  # reason `Vehicle#detach_inventory` gives: it is derived, not entered, and the
  # delete behind it must not turn on whether this row validates.
  def freeze_location!(label)
    update_column(:location, label)
  end

  def claim_free_name!
    taken = self.class.where(holder_type:, holder_id:).order(:id).lock
      .pluck(:id, :name, :slug)
      .reject { |taken_id, _, _| taken_id == id }
    names = taken.map { |_, taken_name, _| taken_name.downcase }
    slugs = taken.map { |_, _, taken_slug| taken_slug }

    return if names.exclude?(name.downcase) && slugs.exclude?(self.class.slug_for(name))

    suffix = (2..).find do |candidate|
      names.exclude?("#{name} (#{candidate})".downcase) &&
        slugs.exclude?(self.class.slug_for("#{name} (#{candidate})"))
    end

    claimed = "#{name} (#{suffix})"

    # Past validation for the same reason, and the slug alongside the name rather
    # than left to `before_save`: skipping the callback would strand the old slug,
    # which is one of the two indexes this exists to keep clear. `slug_for` is the
    # derivation that callback uses.
    update_columns(name: claimed, slug: self.class.slug_for(claimed), updated_at: Time.zone.now)
  end
end
