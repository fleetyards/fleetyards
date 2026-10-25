# frozen_string_literal: true

class Inventory < ApplicationRecord
  include ActiveStorageVariants
  include InventoryStock

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 24

  include LinkedLocations

  belongs_to :holder, polymorphic: true, touch: true
  links_location :location
  belongs_to :vehicle, optional: true

  inventory_items_association :inventory_items
  positions_association :inventory_positions

  has_one_attached :image
  validates :image, no_vector_image: true

  # The contracts delivering here. Nullified with the row by the foreign key,
  # which is what account deletion relies on.
  has_many :destined_fleet_contracts, class_name: "FleetContract",
    foreign_key: :destination_inventory_id, inverse_of: :destination_inventory, dependent: nil

  # The inventories a user created by hand, as opposed to the ones a ship
  # provisioned for itself.
  scope :hand_made, -> { where(vehicle_id: nil) }

  # Slugs are unique among these only. Two Ironclads produce the same slug, so a
  # ship inventory is addressed through its ship instead.
  scope :addressable_by_slug, -> { hand_made }

  PERSONAL_NAME = "Personal Inventory"

  validates :name, presence: true
  validates :name, uniqueness: {case_sensitive: false, scope: [:holder_type, :holder_id]},
    unless: :vehicle_id?
  validate :personal_keeps_its_name, if: -> { persisted? && personal? }

  # Every user has one, and personal contracts deliver into it, so it is not
  # theirs to remove. The account going away takes it along.
  before_destroy :refuse_to_destroy_personal, prepend: true

  # Created the first time anything asks for it rather than for every account
  # up front. A hand-made inventory the user already named that way becomes
  # the personal one, so they do not end up with two.
  def self.personal_for(holder)
    find_by(holder:, personal: true) || provision_personal(holder)
  end

  # Two first reads racing are settled by the partial unique index on the
  # holder; the savepoint keeps the loser's transaction usable for the re-read.
  def self.provision_personal(holder)
    transaction(requires_new: true) do
      adopted = hand_made.where(holder:)
        .where("lower(name) = :name OR slug = :slug", name: PERSONAL_NAME.downcase, slug: slug_for(PERSONAL_NAME))
        .order(Arel.sql("lower(name) = #{connection.quote(PERSONAL_NAME.downcase)} DESC"), :created_at)
        .lock
        .first

      if adopted
        adopted.update_columns(personal: true, updated_at: Time.zone.now)
        adopted
      else
        create!(holder:, name: PERSONAL_NAME, personal: true)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    find_by!(holder:, personal: true)
  end

  # A ship inventory comes into existence with its first deposit, named after the
  # ship it rides in.
  # One listener: the person who holds it. `holder` is polymorphic and only
  # User holds inventories today, so anything else is left alone rather than
  # guessed at -- a ship's inventory is the holder's too, reached through
  # `vehicle`, not through a holder of its own.
  private def broadcast_inventory_change
    return unless holder.is_a?(::User)

    broadcast_safely(HangarInventoryChannel, holder, {inventoryId: id, inventorySlug: slug})
  end

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

  private def personal_keeps_its_name
    return unless will_save_change_to_name?

    errors.add(:name, :personal_inventory_name)
  end

  private def refuse_to_destroy_personal
    return unless personal?
    return if destroyed_by_association

    errors.add(:base, :personal_inventory,
      message: I18n.t("activerecord.errors.messages.personal_inventory_not_deletable"))
    throw(:abort)
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
