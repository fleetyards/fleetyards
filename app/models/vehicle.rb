# frozen_string_literal: true

require "csv"
require "lexorank/rankable"

class Vehicle < ApplicationRecord
  # `name` and `serial` are whatever the owner typed, and a user's vehicles are
  # destroyed along with the account.
  include ErasableVersionsConcern
  include ActiveStorageVariants
  include LinkedLocations

  attr_accessor :update_reason, :update_reason_description, :author_id

  # Scoped to the thread so a Sidekiq worker running one user's hangar sync
  # cannot switch the callback off for every other job in the process. Set
  # through `.with_bundled_snub_crafts`, which restores it.
  thread_mattr_accessor :skip_bundled_snub_crafts, instance_accessor: false, default: false

  # A loaner and a bundled snub craft are derived rows: `wanted`,
  # `hidden_by_user` and `hidden` are recomputed from the parent on every parent
  # save, so a version on one records a calculation rather than a decision.
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
      name serial wanted flagship public name_visible sale_notify hidden hidden_by_user
      loaner bought_via model_id model_paint_picture_id alternative_names
    ],
    if: ->(record) { !record.loaner? && !record.bundled? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
  paginates_per 24
  max_paginates_per 240
  per_page_steps [*PageSizes.up_to(max_per_page), :all]

  # `hidden` is the loaner deduplication below; `hidden_by_user` is the owner
  # taking a ship out of their hangar while the sync keeps matching it.
  scope :visible, -> { where(hidden: false, hidden_by_user: false) }

  # Owned paints are `vehicle_paints` now, and the picture is chosen in the
  # gallery. Ignored until the column is dropped, so the release before this one
  # keeps reading it while this one boots.
  self.ignored_columns += ["model_paint_id"]

  belongs_to :model
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

  rank!(group_by: :user)

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces
  has_many :public_hangar_groups,
    -> { where(public: true) },
    class_name: "HangarGroup",
    source: :hangar_group,
    through: :task_forces

  has_many :fleet_vehicles, dependent: :destroy

  has_many :vehicle_loadouts, dependent: :destroy

  # Removed by the foreign key's cascade, which also covers the bulk delete.
  has_many :log_entries, class_name: "VehicleLogEntry", dependent: nil
  has_many :public_log_entries, -> { public_entries }, class_name: "VehicleLogEntry"

  has_one_attached :image

  # One of the model's own gallery pictures, picked rather than uploaded.
  belongs_to :model_image, class_name: "Image", optional: true
  # Only a new pick is checked: an image disabled later must not block every
  # other save of the vehicle, the hangar sync's among them.
  validate :model_image_from_own_model, if: -> { model_image_id? && will_save_change_to_model_image_id? }
  before_validation :drop_model_image_of_another_model, if: :will_save_change_to_model_id?

  # Or one of the model's paints' store image, in the gallery beside them.
  belongs_to :model_paint_picture, class_name: "ModelPaint", optional: true
  validate :model_paint_picture_from_own_model, if: -> { model_paint_picture_id? && will_save_change_to_model_paint_picture_id? }
  before_validation :drop_model_paint_picture_of_another_model, if: :will_save_change_to_model_id?
  # One gallery pick at a time: picking one source replaces the other, so a
  # client sending only the new pick never trips the database check.
  before_validation :keep_one_gallery_picture

  # Where the owner left the ship. Only ever shown to the owner: a public
  # hangar saying where a ship is parked is an invitation.
  links_location :location
  validates :linked_location, presence: true, if: :location_id?
  validates :image, no_vector_image: true

  # The dedication plaque. Unlike `location` it is public with the vehicle: a
  # launch is history, not where the ship sits now.
  links_location :launch_port, foreign_key: :launch_port_location_id, as: :launch_port_location
  validates :launch_port_location, presence: true, if: :launch_port_location_id?
  DEDICATION_LIMIT = 280
  PLAQUE_LINE_LIMIT = 100
  validates :dedication, length: {maximum: DEDICATION_LIMIT}
  validates :affiliation, :launch_port, length: {maximum: PLAQUE_LINE_LIMIT}
  # Who the plaque names as captain, in place of the owner's display name.
  normalizes :plaque_captain, with: ->(name) { name.squish.presence }
  validates :plaque_captain, length: {maximum: User::DISPLAY_NAME_LIMIT}
  # The lore group the plaque credits as the ship's operations crew. Their names
  # and sides of the law live with the plaque in the frontend.
  OPERATIONS_GROUPS = %w[
    uee mercenary_guild itg cfp shubin nine_tails headhunters xenothreat rough_and_ready
  ].freeze
  validates :operations_group, inclusion: {in: OPERATIONS_GROUPS}, allow_blank: true

  # How the plaque is drawn. `manufacturer` is the style of the company that built
  # the ship. Every style but the default is a supporter perk: once the owner
  # stops supporting, the plaque keeps its style until it is next edited.
  PLAQUE_STYLES = %w[brass hud gunmetal blueprint salvage glass carbon walnut neon manufacturer].freeze
  DEFAULT_PLAQUE_STYLE = "brass"
  validates :plaque_style, inclusion: {in: PLAQUE_STYLES}, allow_blank: true
  PLAQUE_ATTRS = %w[dedication launched_on launch_port launch_port_location_id affiliation operations_group].freeze

  # The plaque as a picture, for the link preview of a shared plaque. The server
  # cannot draw the plaque, so the owner's browser renders it on every save.
  has_one_attached :plaque_image
  validates :plaque_image, no_vector_image: true
  # Served to anyone the link reaches, so only what a browser rendering of the
  # plaque can be: a picture, and a small one.
  PLAQUE_IMAGE_TYPES = %w[image/png image/jpeg image/webp].freeze
  PLAQUE_IMAGE_MAX_BYTES = 3.megabytes
  validate :plaque_image_is_a_small_picture, if: -> { attachment_changes.key?("plaque_image") }
  # Without a dedication there is no plaque, and no picture of one to keep.
  after_save :purge_plaque_image, if: -> { saved_change_to_dedication? && dedication.blank? && plaque_image.attached? }

  has_one :inventory, dependent: nil

  has_many :vehicle_modules, dependent: :destroy
  has_many :model_modules, through: :vehicle_modules

  has_many :vehicle_upgrades, dependent: :destroy
  has_many :model_upgrades, through: :vehicle_upgrades

  has_many :vehicle_paints, dependent: :destroy
  has_many :model_paints, through: :vehicle_paints
  # A paint of the old model is not a paint this ship can own.
  after_save :drop_paints_of_another_model, if: :saved_change_to_model_id?

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
      :task_forces, :hangar_groups, :module_package, {vehicle_loadouts: :items},
      {model: Model.rendered_associations},
      :model_paints,
      {model_paint_picture: ModelPaint.attachment_preloads},
      {parent_vehicle: :model},
      {image_attachment: :blob},
      {model_image: {file_attachment: :blob}},
      :user,
      :linked_location,
      :launch_port_location
    ]
  end

  # The registration the game prints on a ship, such as `L8-4261-HA`. Which
  # positions may hold letters is not settled, so every position accepts both.
  SERIAL_FORMAT = /\A[A-Z0-9]{2}-[A-Z0-9]{4}-[A-Z0-9]{2}\z/

  validates :serial, uniqueness: {scope: :user_id}, allow_nil: true
  # Only on change: thousands of serials predate the format and stay readable,
  # and a vehicle carrying one must still save its other fields.
  validate :serial_in_game_format, if: -> { serial.present? && serial_changed? }
  validate :model_must_be_player_ownable

  NULL_ATTRS = %w[name serial dedication launch_port affiliation operations_group plaque_style].freeze

  enum :bought_via,
    {pledge_store: 0, ingame: 1},
    prefix: true

  before_validation :normalize_serial, if: :serial_changed?
  before_validation :force_ingame_bought_via
  before_save :nil_if_blank
  # After nil_if_blank, so a blank sent for an empty line is not an edit.
  before_save :drop_supporter_plaque_style, if: :drop_supporter_plaque_style?
  before_save :set_module_package
  before_save :reset_pledge_id_if_wanted
  before_save :reset_hidden_by_user_if_wanted
  before_save :update_slugs
  before_create :setup_rank

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
    "modelProductionStatus desc", "modelFocus asc", "modelFocus desc", "rank asc", "rank desc"
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

  # Mirrors what the ship shows: an upload wins over a gallery pick, and a pick
  # of an image that has since been disabled or lost its file falls back to the
  # stock render.
  IMAGE_SOURCE_FILTERS = %w[custom upload gallery default].freeze

  UPLOADED_IMAGE_SQL = <<~SQL.squish
    EXISTS (
      SELECT 1 FROM active_storage_attachments
      WHERE active_storage_attachments.record_type = 'Vehicle'
        AND active_storage_attachments.record_id = vehicles.id
        AND active_storage_attachments.name = 'image'
    )
  SQL

  GALLERY_IMAGE_SQL = <<~SQL.squish
    EXISTS (
      SELECT 1 FROM images
      INNER JOIN active_storage_attachments
        ON active_storage_attachments.record_type = 'Image'
        AND active_storage_attachments.record_id = images.id
        AND active_storage_attachments.name = 'file'
      WHERE images.id = vehicles.model_image_id
        AND images.enabled = TRUE
    )
  SQL

  scope :image_source_eq, ->(source) {
    case source
    when "upload" then where(UPLOADED_IMAGE_SQL)
    when "gallery" then where(GALLERY_IMAGE_SQL).where.not(UPLOADED_IMAGE_SQL)
    when "custom" then where(UPLOADED_IMAGE_SQL).or(where(GALLERY_IMAGE_SQL))
    when "default" then where.not(UPLOADED_IMAGE_SQL).where.not(GALLERY_IMAGE_SQL)
    else all
    end
  }

  # A blank dedication is stored as NULL (see `NULL_ATTRS`), and without one
  # there is no plaque.
  ransacker :has_dedication, type: :boolean do
    Arel.sql("vehicles.dedication IS NOT NULL")
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "alternative_names", "beam", "bought_via", "bundled", "classification", "created_at", "flagship",
      "focus", "hangar_groups", "has_dedication", "height", "hidden", "id", "id_value", "length", "loaner",
      "manufacturer", "model_id", "model_paint_picture_id", "module_package_id", "name", "name_visible",
      "notify", "on_sale", "pledge_price", "price", "production_status", "public", "rank", "rsi_pledge_id",
      "rsi_pledge_synced_at", "sale_notify", "search", "serial", "size", "slug", "updated_at",
      "user_id", "vehicle_id", "wanted"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "fleet_vehicles", "hangar_groups", "model", "model_modules", "model_paints", "model_upgrades",
      "module_package", "public_hangar_groups", "task_forces", "user", "vehicle_modules",
      "vehicle_upgrades"
    ]
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[image_source_eq]
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

  # A ship its owner hid stays out of every public view, whatever its own
  # `public` says, and comes back with that setting when it is unhidden.
  def self.public
    where(public: true, hidden_by_user: false)
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
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  # A vehicle's pages are addressed by id or by serial. A serial may look like
  # an id, so an id that names no vehicle in scope is tried as a serial too.
  def self.find_by_id_or_serial!(identifier)
    identifier = identifier.to_s
    vehicle = find_by(id: identifier) if identifier.match?(UUID_FORMAT)

    vehicle || find_by!(serial: identifier.upcase)
  end

  # Strips and upcases, and sets the dashes into a serial typed without them.
  def self.normalized_serial(value)
    serial = value.to_s.strip.upcase
    compact = serial.delete("- ")
    return serial unless compact.match?(/\A[A-Z0-9]{8}\z/)

    "#{compact[0, 2]}-#{compact[2, 4]}-#{compact[6, 2]}"
  end

  def self.game_serial(value)
    serial = normalized_serial(value)
    serial if SERIAL_FORMAT.match?(serial)
  end

  ADDRESS_ID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i
  ADDRESS_SERIAL = /\A[0-9a-z]{2}-[0-9a-z]{4}-[0-9a-z]{2}/i

  # A ship's address in its owner's hangar -- `l8-4261-ha-contorta`,
  # `<id>-contorta`, `<id>` -- leads with its serial or its id; the name after it
  # is there to read and is never looked up.
  def self.at_address(address)
    address = address.to_s

    if (id = address[ADDRESS_ID])
      where(id: id.downcase)
    elsif (serial = address[ADDRESS_SERIAL])
      where(serial: serial.upcase)
    else
      none
    end
  end

  def self.delete_with_dependents(vehicle_ids)
    return 0 if vehicle_ids.blank?

    transaction do
      vehicle_ids |= descendants_of(vehicle_ids)
      loaner_groups = where(id: vehicle_ids, loaner: true).distinct.pluck(:user_id, :model_id)

      detach_inventories(vehicle_ids)

      loadout_ids = VehicleLoadout.where(vehicle_id: vehicle_ids).pluck(:id)
      erase_versions("VehicleLoadout", loadout_ids)
      VehicleLoadout.where(id: loadout_ids).delete_all

      delete_images(vehicle_ids)

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

  # `Attachment#purge_later` touches its record, which would load every vehicle
  # being deleted and run the broadcasts this path exists to skip. The rows go
  # now and the files once nothing can roll the delete back.
  private_class_method def self.delete_images(vehicle_ids)
    attachments = ActiveStorage::Attachment.where(record_type: name, name: %w[image plaque_image], record_id: vehicle_ids)
    blob_ids = attachments.pluck(:blob_id)
    return if blob_ids.empty?

    attachments.delete_all

    ActiveRecord.after_all_transactions_commit do
      ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge_later)
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

  # `hidden` is a property of a whole (model, wanted, hidden_by_user) group
  # rather than of a row -- exactly one visible -- so deleting a loaner can
  # leave its group with none.
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
      .group_by { |loaner| [loaner.user_id, loaner.model_id, loaner.wanted, loaner.hidden_by_user] }
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

  # Hidden ships are only listed through the hangar's filter, so one moved to
  # the wishlist would be out of reach.
  def reset_hidden_by_user_if_wanted
    return unless wanted?

    self.hidden_by_user = false
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

  # The bulk counterpart of `schedule_fleet_vehicle_update`, for writes that
  # skip the callback. Queued once the outermost transaction commits, so a worker
  # cannot read the hangar as it was before the write.
  def self.schedule_fleet_vehicle_updates(vehicle_ids)
    ids = visible.where(id: vehicle_ids).ids
    return if ids.empty?

    ActiveRecord.after_all_transactions_commit do
      ids.each_slice(1000) { |slice| Updater::FleetVehicleUpdateJob.perform_bulk(slice.zip) }
    end
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

  # The parents of the given models whose `add_loaners` would change something:
  # one missing a listed loaner, holding one its model no longer lists, a
  # duplicate, or one whose `wanted` or `hidden_by_user` differs from its own,
  # or a loaner in a group without exactly one visible row. Walking every parent
  # instead takes hours, and on most runs none of them needs a write.
  def self.out_of_sync_loaner_parent_ids(model_ids)
    return [] if model_ids.blank?

    connection.select_values(sanitize_sql_array([<<~SQL.squish, model_ids]))
      WITH parents AS (
        SELECT id, user_id, model_id, wanted, hidden_by_user FROM vehicles
        WHERE loaner = FALSE AND model_id IN (?)
      ),
      listed AS (
        SELECT model_id, loaner_model_id FROM model_loaners WHERE hidden = FALSE
      ),
      children AS (
        SELECT loaners.id, loaners.user_id, loaners.model_id, loaners.wanted, loaners.hidden_by_user,
          parents.id AS parent_id, parents.model_id AS parent_model_id, parents.wanted AS parent_wanted,
          parents.hidden_by_user AS parent_hidden_by_user
        FROM vehicles loaners
        JOIN parents ON parents.id = loaners.vehicle_id AND parents.user_id = loaners.user_id
        WHERE loaners.loaner = TRUE
      ),
      broken_groups AS (
        SELECT user_id, model_id, wanted, hidden_by_user FROM vehicles
        WHERE loaner = TRUE
        GROUP BY user_id, model_id, wanted, hidden_by_user
        HAVING count(*) FILTER (WHERE hidden = FALSE) <> 1
      )
      SELECT parents.id FROM parents
      JOIN listed ON listed.model_id = parents.model_id
      LEFT JOIN children ON children.parent_id = parents.id AND children.model_id = listed.loaner_model_id
      WHERE children.id IS NULL
      UNION
      SELECT children.parent_id FROM children
      LEFT JOIN listed ON listed.model_id = children.parent_model_id AND listed.loaner_model_id = children.model_id
      WHERE listed.model_id IS NULL
        OR children.wanted IS DISTINCT FROM children.parent_wanted
        OR children.hidden_by_user IS DISTINCT FROM children.parent_hidden_by_user
      UNION
      SELECT parent_id FROM children GROUP BY parent_id, model_id HAVING count(*) > 1
      UNION
      SELECT children.parent_id FROM children
      JOIN broken_groups ON broken_groups.user_id = children.user_id
        AND broken_groups.model_id = children.model_id
        AND broken_groups.wanted IS NOT DISTINCT FROM children.wanted
        AND broken_groups.hidden_by_user = children.hidden_by_user
    SQL
  end

  def add_loaners
    return if loaner?

    remove_unlisted_loaners

    model.loaners.each do |model_loaner|
      create_loaner(model_loaner)
    end
  end

  def remove_loaners
    return if loaner?

    destroy_loaners(Vehicle.where(loaner: true, vehicle_id: id, user_id:))
  end

  # The loaner import drops a pairing RSI no longer lists, but the rows it
  # created for this parent would otherwise stay in the hangar and in fleets:
  # nothing below walks a loaner model the parent's model does not name.
  def remove_unlisted_loaners
    destroy_loaners(
      Vehicle.where(loaner: true, vehicle_id: id, user_id:).where.not(model_id: model.loaners.select(:id))
    )
  end

  def create_loaner(model_loaner)
    # `vehicle_id` already ties the row to this parent, so scoping the lookup by
    # `wanted` too only makes it miss the rows written under the previous value:
    # the parent flips, a second set is created, and the first is stranded with
    # a stale flag that then reaches fleets.
    #
    # A parent can still hold several rows for one loaner model -- the sets the
    # old lookup stranded. Updating only one would strand the rest again on the
    # next flip, so the visible or oldest row stays and the others go.
    existing_loaner, *duplicates = Vehicle.where(loaner: true, vehicle_id: id, model_id: model_loaner.id, user_id:)
      .order(:hidden, :created_at).to_a
    duplicates.each(&:destroy)

    if existing_loaner.present?
      existing_loaner.update(
        wanted:,
        hidden_by_user:,
        hidden: Vehicle.where(loaner: true, model_id: model_loaner.id, wanted:, hidden_by_user:, user_id:, hidden: false)
          .where.not(id: existing_loaner.id).exists?
      )

      # A duplicate or the row's old group may have been the only visible
      # loaner of that group, one another parent's loaner still sits in.
      if duplicates.any? || existing_loaner.saved_change_to_wanted? || existing_loaner.saved_change_to_hidden_by_user?
        reveal_loaner_groups([model_loaner.id])
      end

      return
    end

    Vehicle.create(
      loaner: true,
      model_id: model_loaner.id,
      user_id:,
      vehicle_id: id,
      public: false,
      wanted:,
      hidden_by_user:,
      hidden: Vehicle.exists?(loaner: true, model_id: model_loaner.id, wanted:, hidden_by_user:, user_id:)
    )
  end

  # One loaner of a model stays visible per wanted and hidden_by_user state.
  # Destroying rows can take a group's visible one with it, so the oldest
  # remaining row takes over.
  private def destroy_loaners(scope)
    model_ids = scope.distinct.pluck(:model_id)
    return if model_ids.empty?

    scope.destroy_all

    reveal_loaner_groups(model_ids)
  end

  private def reveal_loaner_groups(model_ids)
    Vehicle.where(loaner: true, user_id:, model_id: model_ids).to_a
      .group_by { |loaner| [loaner.model_id, loaner.wanted, loaner.hidden_by_user] }
      .each_value do |group|
        next if group.any? { |loaner| !loaner.hidden? }

        group.min_by(&:created_at).update(hidden: false)
      end
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
      existing.update(wanted:, hidden_by_user:) if existing.wanted != wanted || existing.hidden_by_user != hidden_by_user
      return
    end

    return if self.class.skip_bundled_snub_crafts

    Vehicle.create(
      bundled: true,
      model_id: snub_craft_model.id,
      user_id:,
      vehicle_id: id,
      public: false,
      wanted:,
      hidden_by_user:
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
    else
      HangarCreateChannel.broadcast_to(user, to_jbuilder_hash)
    end
  end

  def broadcast_destroy
    return if loaner? || !notify?

    if wanted?
      WishlistDestroyChannel.broadcast_to(user, to_jbuilder_hash)
    else
      HangarDestroyChannel.broadcast_to(user, to_jbuilder_hash)
    end
  end

  def export_name
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
      associations: [:model_paints, :model_paint_picture, :model_upgrades, :model_modules, :module_package, :hangar_groups, :task_forces,
        model: [:manufacturer]]
    ).call

    super
  end

  protected def normalize_serial
    self.serial = self.class.normalized_serial(serial) if serial.present?
  end

  private def serial_in_game_format
    errors.add(:serial, :serial_format) unless SERIAL_FORMAT.match?(serial)
  end

  # A ship the pledge store never sells cannot have been bought there, whichever
  # way the row arrived -- by hand, through an import, or from a sync that
  # stamps every entry it creates as a store purchase.
  protected def force_ingame_bought_via
    return if model.blank? || !model.ingame_only?

    self.bought_via = :ingame
  end

  # `move_to!` takes an index into the owner's whole rank group, which holds the
  # wishlist, hidden vehicles and loaners as well as whatever the caller is
  # looking at, so the place is given by a neighbour instead.
  #
  # Only the rank is written: a full save would re-run the loaner, snub craft
  # and fleet callbacks for a change none of them read.
  def move_next_to!(neighbour, after:)
    # A neighbour without a rank has no place to be counted from.
    self.class.rank_unranked!(user_id)

    self.class.lexorank_ranking.with_lock_if_enabled(self) do
      neighbour_rank = Vehicle.where(id: neighbour.id).pick(:rank)
      index = Vehicle.ranked.where(user_id:).where.not(id:).where(rank: ...neighbour_rank).count

      update_columns(rank: move_to(after ? index + 1 : index))
    end

    # Straight to the channels rather than through `broadcast_update`, which
    # stays quiet for loaners and for ships an import created: moving either
    # still changes the order every open hangar shows.
    WishlistChannel.broadcast_to(user, to_jbuilder_hash)
    HangarChannel.broadcast_to(user, to_jbuilder_hash)
  end

  RANK_WIDTH = 4
  RANK_SPACE = 35 * 36**(RANK_WIDTH - 1)
  RANK_DEFAULT_ORDER = "vehicles.flagship DESC, vehicles.name ASC, models.name ASC, " \
    "vehicles.created_at ASC, vehicles.id ASC"

  # Gives an owner's unranked vehicles a rank, and leaves every ranked one where
  # it is.
  #
  # A hangar with no ranks at all is ranked in the order it shows by default, so
  # a custom order starts from what the owner already sees. The ranks are
  # fixed-width base-36 strings spread evenly below "z000", which leaves a few
  # hundred values between neighbours for the largest hangar (~6k vehicles)
  # before lexorank has to grow a rank by a character. Nothing may start with
  # "z": lexorank treats "z" as the upper bound and raises when asked for a rank
  # after one that begins with it.
  #
  # A hangar that has ranks keeps them, and its unranked vehicles are appended
  # after the last one in that same default order.
  # Ships a backfill has not reached yet have no rank, and would come after the
  # ranked ones in no order at all. Behind the rank they fall into the order the
  # backfill will give them, so ranking them changes nothing on screen.
  def self.with_rank_tiebreak(sorts)
    return sorts unless Array(sorts).any? { |sort| sort.start_with?("rank ") }

    Array(sorts) + ["flagship desc", "name asc", "model_name asc", "created_at asc"]
  end

  def self.rank_unranked!(user_id)
    return if user_id.blank? || !where(user_id:, rank: nil).exists?

    transaction do
      lexorank_ranking.with_lock_if_enabled(new(user_id:), transaction: true) do
        unranked_ids = where(user_id:, rank: nil)
          .left_joins(:model)
          .order(Arel.sql(RANK_DEFAULT_ORDER))
          .pluck(:id)

        if where(user_id:).where.not(rank: nil).exists?
          append_ranks(user_id, unranked_ids)
        else
          spread_ranks(unranked_ids)
        end
      end
    end
  end

  private_class_method def self.spread_ranks(ids)
    ranks = ids.each_with_index.map do |id, index|
      [id, ((index + 1) * RANK_SPACE / (ids.size + 1)).to_s(36).rjust(RANK_WIDTH, "0")]
    end

    ranks.each_slice(1000) do |slice|
      values = slice.map { |id, rank| "(#{connection.quote(id)}::uuid, #{connection.quote(rank)})" }.join(", ")

      connection.execute(<<~SQL.squish)
        UPDATE vehicles SET rank = ranks.rank
        FROM (VALUES #{values}) AS ranks(id, rank)
        WHERE vehicles.id = ranks.id
      SQL
    end
  end

  private_class_method def self.append_ranks(user_id, ids)
    last = where(user_id:).maximum(:rank)

    ids.each do |id|
      last = lexorank_ranking.value_between(last, nil)
      where(id:).update_all(rank: last)
    end
  end

  private def plaque_image_is_a_small_picture
    blob = plaque_image.blob
    return if blob.blank?
    return if PLAQUE_IMAGE_TYPES.include?(blob.content_type) && blob.byte_size <= PLAQUE_IMAGE_MAX_BYTES

    errors.add(:plaque_image, :invalid)
  end

  private def purge_plaque_image
    plaque_image.purge_later
  end

  def effective_plaque_style
    plaque_style.presence || DEFAULT_PLAQUE_STYLE
  end

  private def drop_supporter_plaque_style?
    plaque_style.present? && plaque_style != DEFAULT_PLAQUE_STYLE &&
      PLAQUE_ATTRS.any? { |attr| will_save_change_to_attribute?(attr) } &&
      !user&.supporter?
  end

  private def drop_supporter_plaque_style
    self.plaque_style = DEFAULT_PLAQUE_STYLE
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end

  # Held until commit: the rank is read from the user's last vehicle, so two
  # creates for one hangar would otherwise pick the same value and the second
  # would fail on the unique index.
  private def setup_rank
    return if rank.present? || user_id.blank?

    self.class.lexorank_ranking.with_lock_if_enabled(self, transaction: true) do
      move_to_end
    end
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

  private def model_image_from_own_model
    return if model_image.present? && model_image.enabled? &&
      model_image.gallery_type == "Model" && model_image.gallery_id == model_id

    errors.add(:model_image, :invalid)
  end

  # A picture of the old model would show the wrong ship.
  private def drop_model_image_of_another_model
    self.model_image_id = nil if model_image.present? && model_image.gallery_id != model_id
  end

  private def model_paint_picture_from_own_model
    return if model_paint_picture.present? && model_paint_picture.model_id == model_id &&
      model_paint_picture.store_image.attached?

    errors.add(:model_paint_picture, :invalid)
  end

  private def drop_model_paint_picture_of_another_model
    self.model_paint_picture_id = nil if model_paint_picture.present? && model_paint_picture.model_id != model_id
  end

  private def keep_one_gallery_picture
    return unless model_image_id? && model_paint_picture_id?

    if will_save_change_to_model_paint_picture_id?
      self.model_image_id = nil
    else
      self.model_paint_picture_id = nil
    end
  end

  private def drop_paints_of_another_model
    vehicle_paints.joins(:model_paint).where.not(model_paints: {model_id:}).destroy_all
  end
end
