# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                   :uuid             not null, primary key
#  alternative_names    :string
#  bought_via           :integer          default(0)
#  bundled              :boolean          default(FALSE), not null
#  flagship             :boolean          default(FALSE)
#  hidden               :boolean          default(FALSE)
#  loaner               :boolean          default(FALSE)
#  name                 :string(255)
#  name_visible         :boolean          default(FALSE)
#  notify               :boolean          default(TRUE)
#  public               :boolean          default(FALSE)
#  rsi_pledge_synced_at :datetime
#  sale_notify          :boolean          default(FALSE)
#  serial               :string
#  slug                 :string
#  wanted               :boolean          default(FALSE)
#  created_at           :datetime
#  updated_at           :datetime
#  model_id             :uuid
#  model_paint_id       :uuid
#  module_package_id    :uuid
#  rsi_pledge_id        :string
#  user_id              :uuid
#  vehicle_id           :uuid
#
# Indexes
#
#  index_vehicles_on_hidden_and_loaner       (hidden,loaner)
#  index_vehicles_on_model_id_and_id         (model_id,id)
#  index_vehicles_on_serial_and_user_id      (serial,user_id) UNIQUE
#  index_vehicles_on_user_id                 (user_id)
#  index_vehicles_on_vehicle_id_and_bundled  (vehicle_id,bundled)
#
require "csv"

class Vehicle < ApplicationRecord
  # `name` and `serial` are whatever the owner typed, and a user's vehicles are
  # destroyed along with the account.
  include ErasableVersionsConcern

  attr_accessor :update_reason, :update_reason_description, :author_id

  # Scoped to the thread so a Sidekiq worker running one user's hangar sync
  # cannot switch the callback off for every other job in the process. Set
  # through `.with_bundled_snub_crafts`, which restores it.
  thread_mattr_accessor :skip_bundled_snub_crafts, instance_accessor: false, default: false

  # A loaner and a bundled snub craft are derived rows: `wanted` and `hidden`
  # are recomputed from the parent on every parent save, so a version on one
  # records a calculation rather than a decision.
  #
  # That predicate cannot tell a machine write from a user's: the hangar sync
  # writes `name` and `wanted` on the same non-loaner rows a rename does. The
  # importers are held out at their entry points instead, with
  # `PaperTrail.request(enabled: false)`.
  #
  # `:destroy` is deliberately absent rather than taken from
  # `VersionedItem::RECORDED_EVENTS`. `ErasableVersionsConcern` above registers
  # its `after_destroy` first, and rails runs `after_*` in reverse definition
  # order, so paper_trail's destroy version would be written and then deleted in
  # the same transaction.
  has_paper_trail on: %i[create update],
    only: %i[
      name serial wanted flagship public name_visible sale_notify hidden
      loaner bought_via model_id model_paint_id alternative_names
    ],
    if: ->(record) { !record.loaner? && !record.bundled? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
  paginates_per 30
  max_paginates_per 240
  per_page_steps [15, 30, 60, 120, 240, :all]

  scope :visible, -> { where(hidden: false) }

  belongs_to :model
  belongs_to :model_paint, optional: true
  belongs_to :user, touch: :hangar_updated_at
  belongs_to :module_package,
    class_name: "ModelModulePackage",
    optional: true
  belongs_to :parent_vehicle,
    class_name: "Vehicle",
    foreign_key: :vehicle_id,
    inverse_of: :child_vehicles,
    optional: true
  has_many :child_vehicles,
    class_name: "Vehicle",
    foreign_key: :vehicle_id,
    inverse_of: :parent_vehicle,
    dependent: nil

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces
  has_many :public_hangar_groups,
    -> { where(public: true) },
    class_name: "HangarGroup",
    source: :hangar_group,
    through: :task_forces

  has_many :fleet_vehicles, dependent: :destroy

  has_many :vehicle_loadouts, dependent: :destroy

  has_one :inventory, dependent: nil

  has_many :vehicle_modules, dependent: :destroy
  has_many :model_modules, through: :vehicle_modules

  has_many :vehicle_upgrades, dependent: :destroy
  has_many :model_upgrades, through: :vehicle_upgrades

  # Everything `api/v1/vehicles/_base.jbuilder` reaches for. It renders the whole
  # model partial per vehicle, so `Model.rendered_associations` comes along
  # nested -- without it a hangar pays for every ship picture once per vehicle.
  #
  # `model_modules` is named rather than `vehicle_modules`, because that is what
  # `model_module_ids` reads: preloading the join alone still leaves one query
  # per vehicle, which is invisible until the queries are counted.
  def self.rendered_associations
    [
      :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules,
      :task_forces, :hangar_groups, :module_package, :vehicle_loadouts,
      {model: Model.rendered_associations},
      {model_paint: [:item_prices] + ModelPaint.attachment_preloads},
      {parent_vehicle: :model}
    ]
  end

  validates :serial, uniqueness: {scope: :user_id}, allow_nil: true
  validate :model_must_be_player_ownable

  NULL_ATTRS = %w[name serial].freeze

  enum :bought_via,
    {pledge_store: 0, ingame: 1},
    prefix: true

  before_validation :normalize_serial
  before_save :nil_if_blank
  before_save :set_module_package
  before_save :reset_pledge_id_if_wanted
  before_save :update_slugs

  before_destroy :detach_inventory

  after_create :broadcast_create
  after_destroy :remove_loaners, :remove_bundled_snub_crafts, :broadcast_destroy
  after_save :set_flagship, :update_loaners, :update_bundled_snub_crafts, :reset_hangar_groups
  after_commit :broadcast_update, :schedule_fleet_vehicle_update

  DEFAULT_SORTING_PARAMS = ["flagship desc", "name asc", "model_name asc"]
  ALLOWED_SORTING_PARAMS = [
    "flagship desc", "flagship asc", "name asc", "name desc", "modelName asc", "modelName desc",
    "createdAt asc", "createdAt desc", "updatedAt asc", "updatedAt desc",
    "modelManufacturerName asc", "modelManufacturerName desc", "modelLength asc",
    "modelLength desc", "modelBeam asc", "modelBeam desc", "modelHeight asc",
    "modelHeight desc", "modelMass asc", "modelMass desc", "modelCargo asc", "modelCargo desc",
    "modelPledgePrice asc", "modelPledgePrice desc", "modelPrice asc", "modelPrice desc",
    "modelScmSpeed asc", "modelScmSpeed desc", "modelMaxSpeed asc", "modelMaxSpeed desc",
    "modelGroundMaxSpeed asc", "modelGroundMaxSpeed desc", "modelProductionStatus asc",
    "modelProductionStatus desc", "modelFocus asc", "modelFocus desc"
  ]

  ransack_alias :search, :name_or_model_name_or_model_slug
  ransack_alias :on_sale, :model_on_sale
  ransack_alias :length, :model_length
  ransack_alias :beam, :model_beam
  ransack_alias :height, :model_height
  ransack_alias :price, :model_price
  ransack_alias :pledge_price, :model_pledge_price
  ransack_alias :manufacturer, :model_manufacturer_slug
  ransack_alias :classification, :model_classification
  ransack_alias :focus, :model_focus
  ransack_alias :size, :model_size
  ransack_alias :production_status, :model_production_status
  ransack_alias :hangar_groups, :hangar_groups_slug

  ransacker :bought_via, formatter: proc { |v| Vehicle.bought_via[v] } do |parent|
    parent.table[:bought_via]
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "alternative_names", "beam", "bought_via", "bundled", "classification", "created_at", "flagship",
      "focus", "hangar_groups", "height", "hidden", "id", "id_value", "length", "loaner",
      "manufacturer", "model_id", "model_paint_id", "module_package_id", "name", "name_visible",
      "notify", "on_sale", "pledge_price", "price", "production_status", "public", "rsi_pledge_id",
      "rsi_pledge_synced_at", "sale_notify", "search", "serial", "size", "slug", "updated_at",
      "user_id", "vehicle_id", "wanted"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "fleet_vehicles", "hangar_groups", "model", "model_modules", "model_paint", "model_upgrades",
      "module_package", "public_hangar_groups", "task_forces", "user", "vehicle_modules",
      "vehicle_upgrades"
    ]
  end

  serialize :alternative_names, type: Array, coder: YAML

  def self.bought_via_filters
    Vehicle.bought_via.map do |(item, _index)|
      Filter.new(
        category: "bought_via",
        label: Vehicle.human_enum_name(:bought_via, item),
        value: item
      )
    end
  end

  def self.purchased
    where(wanted: false)
  end

  def self.wanted
    where(wanted: true)
  end

  def self.public
    where(public: true)
  end

  # Run-wide rather than an attribute on each row: `update_bundled_snub_crafts`
  # fires on every save, not only on the ones that create a ship, so a hangar
  # sync that threaded a flag through its writes would leave the next write
  # somebody adds silently back on. Only creation is suppressed -- a snub craft
  # the user already has still follows its parent's `wanted`.
  def self.with_bundled_snub_crafts(enabled)
    previous = skip_bundled_snub_crafts
    self.skip_bundled_snub_crafts = !enabled

    yield
  ensure
    self.skip_bundled_snub_crafts = previous
  end

  # The hangar's bulk deletions go around `destroy`: a wishlist wipe is a few
  # thousand rows and every callback on the way out queries, broadcasts and
  # queues a job per vehicle. What `destroy` would have taken with it has to be
  # cleared here instead, and the list is hand-maintained -- a table added since
  # the last edit is one nobody cleans up. Missing one used to mean an orphaned
  # row nobody noticed; `vehicle_loadouts` has a foreign key, so missing that one
  # raises `ActiveRecord::InvalidForeignKey` and the whole delete rolls back.
  # Wraps itself rather than leaving it to the caller: it is a dozen statements
  # that only make sense together, and a caller already inside a transaction
  # joins this one rather than opening a second.
  def self.delete_with_dependents(vehicle_ids)
    return 0 if vehicle_ids.blank?

    transaction do
      vehicle_ids |= descendants_of(vehicle_ids)
      loaner_groups = where(id: vehicle_ids, loaner: true).distinct.pluck(:user_id, :model_id)

      detach_inventories(vehicle_ids)

      loadout_ids = VehicleLoadout.where(vehicle_id: vehicle_ids).pluck(:id)
      erase_versions("VehicleLoadout", loadout_ids)
      VehicleLoadout.where(id: loadout_ids).delete_all

      VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
      VehicleModule.where(vehicle_id: vehicle_ids).delete_all
      TaskForce.where(vehicle_id: vehicle_ids).delete_all
      FleetVehicle.where(vehicle_id: vehicle_ids).delete_all

      erase_versions("Vehicle", vehicle_ids)

      deleted = where(id: vehicle_ids).delete_all

      revisit_loaner_visibility(loaner_groups)

      deleted
    end
  end

  # The loaners and bundled snub crafts `after_destroy` would have taken with
  # the parent. One level is enough: neither is given loaners or snub crafts of
  # its own, and nothing else ever sets `vehicle_id`.
  private_class_method def self.descendants_of(vehicle_ids)
    where(vehicle_id: vehicle_ids).where(loaner: true)
      .or(where(vehicle_id: vehicle_ids).where(bundled: true))
      .pluck(:id)
  end

  # `hidden` is a property of a whole (model, wanted) group rather than of a row
  # -- exactly one visible -- so deleting a loaner can leave its group with none.
  # The survivor is one already visible where there is one, so a group that was
  # correct apart from the rows that just went keeps the loaner its user sees.
  #
  # `update_columns` skips the `after_commit` that keeps the fleet side in step,
  # and that callback returns early for a hidden vehicle anyway, so the job is
  # queued from here -- after the outermost transaction commits, so a worker
  # picking it up cannot read the hangar as it was before the delete.
  private_class_method def self.revisit_loaner_visibility(loaner_groups)
    return if loaner_groups.blank?

    user_ids, model_ids = loaner_groups.transpose

    flipped = where(loaner: true, user_id: user_ids, model_id: model_ids)
      .group_by { |loaner| [loaner.user_id, loaner.model_id, loaner.wanted] }
      .flat_map do |_group_key, group|
        visible = group.find { |loaner| !loaner.hidden? } || group.first

        group.select do |loaner|
          should_hide = !loaner.equal?(visible)
          next false if loaner.hidden? == should_hide

          loaner.update_columns(hidden: should_hide, updated_at: Time.zone.now)
          true
        end
      end

    return if flipped.empty?

    ActiveRecord.after_all_transactions_commit do
      flipped.each { |loaner| Updater::FleetVehicleUpdateJob.perform_async(loaner.id) }
    end
  end

  # What `Vehicle#detach_inventory` does on a single destroy. Iterated rather
  # than expressed as one `UPDATE`, because both the label and the free name are
  # per row, and the set is bounded by the vehicles carrying an inventory rather
  # than by the vehicles being deleted.
  private_class_method def self.detach_inventories(vehicle_ids)
    Inventory.where(vehicle_id: vehicle_ids)
      .includes(vehicle: :model)
      .find_each do |inventory|
        inventory.freeze_location!(inventory.vehicle.display_name) if inventory.location.blank?
        inventory.claim_free_name!
      end
  end

  # `ErasableVersionsConcern` is an `after_destroy`, and these rows never see
  # one. Leaving the versions behind would leave the names and serials somebody
  # deleted sitting in a table no erasure path reaches.
  private_class_method def self.erase_versions(item_type, item_ids)
    return if item_ids.blank?

    PaperTrail::Version.where(item_type:, item_id: item_ids).delete_all
  end

  def reset_pledge_id_if_wanted
    return unless wanted?

    self.rsi_pledge_id = nil
    self.rsi_pledge_synced_at = nil
  end

  def reset_hangar_groups
    return unless wanted?

    task_forces.destroy_all
  end

  def bought_via_label
    Vehicle.human_enum_name(:bought_via, bought_via)
  end

  def schedule_fleet_vehicle_update
    return if hidden?

    Updater::FleetVehicleUpdateJob.perform_async(id)
  end

  def update_fleet_vehicle
    user.fleet_memberships.kept.each do |fleet_membership|
      fleet_membership.update_fleet_vehicle(self)
    end
  end

  def update_loaners
    return if loaner?

    add_loaners
  end

  def add_loaners
    return if loaner?

    model.loaners.each do |model_loaner|
      create_loaner(model_loaner)
    end
  end

  def remove_loaners
    return if loaner?

    Vehicle.where(loaner: true, vehicle_id: id, user_id:).destroy_all

    Vehicle.where(loaner: true, model_id:, user_id:).find_each do |loaner_vehicle|
      loaner_vehicle.update(
        hidden: Vehicle.where(loaner: true, model_id: loaner_vehicle.model_id, user_id:, hidden: false).where.not(id: loaner_vehicle.id).exists?
      )
    end
  end

  def create_loaner(model_loaner)
    # `vehicle_id` already ties the row to this parent, so scoping the lookup by
    # `wanted` too only makes it miss the rows written under the previous value:
    # the parent flips, a second set is created, and the first is stranded with
    # a stale flag that then reaches fleets.
    existing_loaner = Vehicle.where(loaner: true, vehicle_id: id, model_id: model_loaner.id, user_id:).first

    if existing_loaner.present?
      existing_loaner.update(
        wanted:,
        hidden: Vehicle.where(loaner: true, model_id: model_loaner.id, wanted:, user_id:, hidden: false)
          .where.not(id: existing_loaner.id).exists?
      )

      return
    end

    Vehicle.create(
      loaner: true,
      model_id: model_loaner.id,
      user_id:,
      vehicle_id: id,
      public: false,
      wanted:,
      hidden: Vehicle.exists?(loaner: true, model_id: model_loaner.id, wanted:, user_id:)
    )
  end

  def update_bundled_snub_crafts
    return if loaner? || bundled?

    add_bundled_snub_crafts
  end

  def add_bundled_snub_crafts
    return if loaner? || bundled?

    model.snub_crafts.each do |snub_craft_model|
      create_bundled_snub_craft(snub_craft_model)
    end
  end

  def remove_bundled_snub_crafts
    return if loaner? || bundled?

    Vehicle.where(bundled: true, vehicle_id: id, user_id:).destroy_all
  end

  def create_bundled_snub_craft(snub_craft_model)
    return unless snub_craft_model.player_ownable?

    existing = Vehicle.where(bundled: true, vehicle_id: id, model_id: snub_craft_model.id, user_id:).first

    if existing.present?
      existing.update(wanted:) if existing.wanted != wanted
      return
    end

    return if self.class.skip_bundled_snub_crafts

    Vehicle.create(
      bundled: true,
      model_id: snub_craft_model.id,
      user_id:,
      vehicle_id: id,
      public: false,
      wanted:
    )
  end

  def broadcast_update
    return if loaner? || !notify?

    WishlistChannel.broadcast_to(user, to_jbuilder_hash)
    HangarChannel.broadcast_to(user, to_jbuilder_hash)
  end

  def broadcast_create
    return if loaner? || !notify?

    if wanted?
      WishlistCreateChannel.broadcast_to(user, to_jbuilder_hash)
      Notification.notify!(
        user:,
        type: :wishlist_create,
        title: I18n.t("notifications.wishlist_create.title", model: model.name),
        link: Rails.application.routes.url_helpers.frontend_hangar_path
      )
    else
      HangarCreateChannel.broadcast_to(user, to_jbuilder_hash)
      Notification.notify!(
        user:,
        type: :hangar_create,
        title: I18n.t("notifications.hangar_create.title", model: model.name),
        link: Rails.application.routes.url_helpers.frontend_hangar_path
      )
    end
  end

  def broadcast_destroy
    return if loaner? || !notify?

    if wanted?
      WishlistDestroyChannel.broadcast_to(user, to_jbuilder_hash)
      Notification.notify!(
        user:,
        type: :wishlist_destroy,
        title: I18n.t("notifications.wishlist_destroy.title", model: model.name),
        link: Rails.application.routes.url_helpers.frontend_hangar_path
      )
    else
      HangarDestroyChannel.broadcast_to(user, to_jbuilder_hash)
      Notification.notify!(
        user:,
        type: :hangar_destroy,
        title: I18n.t("notifications.hangar_destroy.title", model: model.name),
        link: Rails.application.routes.url_helpers.frontend_hangar_path
      )
    end
  end

  def export_name
    return model_paint.rsi_name if model_paint.present? && model_paint.rsi_id.present?

    model.rsi_name || model.name
  end

  def display_name
    name.presence || model.name
  end

  def default_inventory_name
    "#{display_name} Inventory"
  end

  def model_manufacturer
    model.manufacturer.name
  end

  def set_flagship
    return unless flagship?

    Vehicle.where(user_id:, flagship: true)
      .where.not(id:)
      .find_each do |vehicle|
      vehicle.update(flagship: false)
    end
  end

  def set_module_package
    return if model_modules.blank?

    self.module_package_id = main_module_package&.id
  end

  def main_module_package
    packages = model.module_packages.select do |package|
      (package.model_module_ids - model_module_ids).empty?
    end

    packages.min_by do |package|
      model_module_ids.size - package.model_module_ids.size
    end
  end

  def to_jbuilder_hash(*_args)
    ActiveRecord::Associations::Preloader.new(
      records: [self],
      associations: [:model_paint, :model_upgrades, :model_modules, :module_package, :hangar_groups, :task_forces,
        model: [:manufacturer]]
    ).call

    super
  end

  protected def normalize_serial
    return if serial.blank?

    self.serial = serial.upcase
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end

  # The foreign key nullifies `vehicle_id`, which would otherwise leave the stock
  # with no hint of where it came from.
  # A ship inventory outlives its ship -- the foreign key nullifies rather than
  # cascades -- so it leaves carrying the ship's name as its location, and a name
  # nothing else of this holder's has claimed.
  #
  # Written past validation: both values are derived rather than entered, and an
  # inventory left invalid by something else entirely -- an image the vector
  # validator now rejects, say -- must not be what stops somebody deleting a
  # ship. `update` would have been worse than either: it returns false and the
  # delete carries on, nulling `vehicle_id` on a row whose label never landed.
  private def detach_inventory
    return if inventory.blank?

    inventory.freeze_location!(display_name) if inventory.location.blank?
    inventory.claim_free_name!
  end

  private def model_must_be_player_ownable
    return if model.blank?
    return if model.player_ownable?

    errors.add(:model, :not_player_ownable)
  end
end
