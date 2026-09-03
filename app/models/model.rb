# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id                                :uuid             not null, primary key
#  active                            :boolean          default(TRUE)
#  adi_map                           :boolean          default(FALSE)
#  beam                              :decimal(15, 2)   default(0.0), not null
#  cargo                             :decimal(15, 2)
#  cargo_holds                       :string
#  classification                    :string(255)
#  description                       :text
#  dock_size                         :integer
#  erkul_identifier                  :string
#  extended_beam                     :decimal(15, 2)
#  extended_fleetchart_offset_beam   :decimal(15, 2)
#  extended_fleetchart_offset_length :decimal(15, 2)
#  extended_height                   :decimal(15, 2)
#  extended_length                   :decimal(15, 2)
#  external_fuel_tanks               :string
#  fleetchart_offset_beam            :decimal(15, 2)
#  fleetchart_offset_length          :decimal(15, 2)
#  focus                             :string(255)
#  fuel_consumption                  :decimal(15, 2)
#  ground                            :boolean          default(FALSE)
#  ground_acceleration               :decimal(15, 2)
#  ground_decceleration              :decimal(15, 2)
#  ground_max_speed                  :decimal(15, 2)
#  ground_reverse_speed              :decimal(15, 2)
#  height                            :decimal(15, 2)   default(0.0), not null
#  hidden                            :boolean          default(TRUE)
#  holo_colored                      :boolean          default(FALSE)
#  hull_doors                        :jsonb
#  hull_health                       :decimal(15, 2)
#  hull_parts                        :jsonb
#  hydrogen_fuel_tank_size           :decimal(15, 2)
#  hydrogen_fuel_tanks               :string
#  images_count                      :integer          default(0)
#  in_game                           :boolean          default(FALSE), not null
#  last_updated_at                   :datetime
#  legacy_slug                       :string
#  length                            :decimal(15, 2)   default(0.0), not null
#  loaners_count                     :integer          default(0), not null
#  main_acceleration                 :decimal(15, 2)
#  mass                              :decimal(15, 2)   default(0.0), not null
#  max_crew                          :integer
#  max_speed                         :decimal(15, 2)
#  min_crew                          :integer
#  model_paints_count                :integer          default(0)
#  module_hardpoints_count           :integer          default(0)
#  name                              :string(255)
#  notified                          :boolean          default(FALSE)
#  on_sale                           :boolean          default(FALSE)
#  personal_inventory                :decimal(15, 2)
#  pitch                             :decimal(15, 2)
#  pitch_boosted                     :decimal(15, 2)
#  player_ownable                    :boolean          default(TRUE), not null
#  pledge_price                      :decimal(15, 2)
#  positions_need_curation           :boolean          default(FALSE)
#  price                             :decimal(15, 2)
#  production_note                   :string(255)
#  production_status                 :string(255)
#  quantum_fuel_tank_size            :decimal(15, 2)
#  quantum_fuel_tanks                :string
#  refuel_boom                       :string
#  retro_acceleration                :decimal(15, 2)
#  reverse_speed_boosted             :decimal(15, 2)
#  roll                              :decimal(15, 2)
#  roll_boosted                      :decimal(15, 2)
#  rsi_beam                          :decimal(15, 2)   default(0.0), not null
#  rsi_cargo                         :decimal(15, 2)
#  rsi_classification                :string
#  rsi_ctm_url                       :string
#  rsi_description                   :text
#  rsi_focus                         :string
#  rsi_height                        :decimal(15, 2)   default(0.0), not null
#  rsi_length                        :decimal(15, 2)   default(0.0), not null
#  rsi_mass                          :decimal(15, 2)   default(0.0), not null
#  rsi_max_crew                      :integer
#  rsi_max_speed                     :decimal(15, 2)
#  rsi_min_crew                      :integer
#  rsi_name                          :string
#  rsi_pitch                         :decimal(15, 2)
#  rsi_pledge_slug                   :string
#  rsi_pledge_value                  :integer
#  rsi_roll                          :decimal(15, 2)
#  rsi_scm_speed                     :decimal(15, 2)
#  rsi_size                          :string
#  rsi_slug                          :string
#  rsi_store_url                     :string
#  rsi_yaw                           :decimal(15, 2)
#  sales_page_url                    :string
#  sc_beam                           :decimal(15, 2)
#  sc_height                         :decimal(15, 2)
#  sc_key                            :string
#  sc_length                         :decimal(15, 2)
#  scm_speed                         :decimal(15, 2)
#  scm_speed_boosted                 :decimal(15, 2)
#  signature_cross_section           :jsonb
#  size                              :string
#  slug                              :string(255)
#  store_images_updated_at           :datetime
#  store_url                         :string(255)
#  upgrade_kits_count                :integer          default(0)
#  videos_count                      :integer          default(0)
#  weapon_pool_size                  :integer
#  yaw                               :decimal(15, 2)
#  yaw_boosted                       :decimal(15, 2)
#  created_at                        :datetime
#  updated_at                        :datetime
#  base_model_id                     :uuid
#  manufacturer_id                   :uuid
#  rsi_chassis_id                    :integer
#  rsi_id                            :integer
#
# Indexes
#
#  index_models_on_base_model_id             (base_model_id)
#  index_models_on_classification            (classification)
#  index_models_on_legacy_slug               (legacy_slug)
#  index_models_on_manufacturer_id           (manufacturer_id)
#  index_models_on_manufacturer_id_and_name  (manufacturer_id,name) UNIQUE
#  index_models_on_production_status         (production_status)
#  index_models_on_size                      (size)
#
class Model < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include RoutingConcern
  include DerivedCargoHolds
  include ActiveStorageVariants
  include AttachmentRansackers

  attr_accessor :update_reason, :update_reason_description, :author_id

  # `name`, `description` and `ground` are here because an admin can edit all
  # three, not because the ship matrix writes them -- an edit with no history is
  # the gap, and the loader's own report reading them is the second reason.
  #
  # The `rsi_*` shadow columns are watched because they are **not** the live
  # column read twice: `mass` differs from `rsi_mass` on 196 of 246 models, and
  # `max_speed`, `pitch`, `yaw` and `roll` on 188. `Rsi::ModelsLoader` writes a
  # shadow on every run but the live column only when RSI moved `time_modified`
  # and the new value is not blank -- so a shadow that moves alone is the matrix
  # saying something we did not adopt, which nothing else records.
  has_paper_trail on: %i[update], only: %i[
    name description ground
    rsi_id rsi_chassis_id rsi_name rsi_description rsi_classification rsi_focus rsi_size rsi_store_url
    rsi_length rsi_beam rsi_height rsi_mass rsi_cargo rsi_min_crew rsi_max_crew
    rsi_scm_speed rsi_max_speed rsi_pitch rsi_yaw rsi_roll
    classification production_status production_note focus pledge_price length beam height mass
    cargo personal_inventory size min_crew max_crew scm_speed max_speed ground_max_speed ground_reverse_speed
    ground_acceleration ground_decceleration pitch yaw roll price
    store_url hydrogen_fuel_tank_size quantum_fuel_tank_size cargo_holds hydrogen_fuel_tanks
    quantum_fuel_tanks external_fuel_tanks refuel_boom sales_page_url
  ], meta: {
    author_id: :author_id,
    reason: :update_reason,
    reason_description: :update_reason_description
  }

  paginates_per 30
  max_paginates_per 240
  per_page_steps [15, 30, 60, 120, 240, :all]

  belongs_to :manufacturer

  # What each build of the game says about this model's mechanics.
  has_many :builds, class_name: "ModelBuild", dependent: :destroy
  has_one :build, -> { current }, class_name: "ModelBuild", inverse_of: :model

  # The newest build of this environment that still describes the model, which is
  # what a model the export dropped falls back to. A hangar entry pointing at a
  # retired ship has to resolve to something.
  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "ModelBuild", inverse_of: :model

  # A mechanics fact resolves the build first, then the column: the build we are
  # on, else the last build of this environment that described the model, else
  # what the row itself says.
  #
  # **The RSI ship matrix is deliberately not a layer here**, though the design
  # sketch had it sitting between the two. Measured before writing it: reading
  # `rsi_mass` and its five siblings above the column changes exactly one value
  # across 246 models, and that one change is a regression. For 30 of the 31
  # ships with no build the column already *holds* the matrix value, because
  # `Rsi::ModelsLoader` writes both. The 31st is the Retaliator Bomber, whose
  # column carries a game-file mass the sc_data loader wrote in April from a
  # build that still shipped it -- promoting the matrix there would replace a
  # real value with a staler one.
  #
  # The matrix earns a layer when it stops being copied into the column, which is
  # the change that moves `rsi_*` out of Model's columns entirely. Until then it
  # is the same value read twice.
  #
  # Build existence also cannot become this catalogue's filter the way it did for
  # equipment and components: 31 of 246 models are concept ships the matrix
  # carries and no build ever will, and filtering on a build row would hide every
  # one of them. `in_game` stays the flag.

  # Whether the build we are on describes this ship.
  #
  # Derived rather than stored. The column it replaces was a single boolean set
  # from whichever environment loaded last, so a ptu load overwrote what live had
  # said and a ship added in ptu appeared in the live view. A build row carries
  # its environment, so the same question has a different answer per source --
  # which is the whole point.
  #
  # This is not the catalogue filter: 31 of 246 models are concept ships no build
  # will ever describe, and hiding them would empty the catalogue of everything
  # not yet flying. `visible` and `active` stay what decides that.
  #
  # `build` is preloaded by `rendered_associations`, so a list costs no queries
  # for this.
  def in_game?
    build.present?
  end
  alias_method :in_game, :in_game?

  # The filter keeps its name -- a ransacker wins over a same-named column -- so
  # `inGameEq` needs no API change. An `EXISTS` rather than the correlated
  # subquery the fact filters use, because this asks whether a row is there
  # rather than what it says, and the unique index answers it directly.
  ransacker(:in_game) do
    source = ::ScData::Source.current

    Arel.sql(
      sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
        EXISTS (
          SELECT 1 FROM model_builds
          WHERE model_builds.model_id = models.id
            AND model_builds.environment = ?
            AND model_builds.version = ?
        )
      SQL
    )
  end

  # The build we are on, or the last one that described the model. A hangar entry
  # pointing at a ship the export dropped still has to resolve to something.
  def facts
    build || last_build
  end

  # An admin correction is a correction to the build we are on, so it has to
  # reach the build as well as the row.
  #
  # Deliberately the same rule the other three catalogues use, rather than the
  # curated-wins layer the design sketched. Measured over the whole paper_trail
  # history: an admin has edited **none** of these 27 facts. What they do curate
  # -- images, `sales_page_url`, dimensions, `pledge_price`, `production_status`,
  # `size`, `cargo` -- is outside the build entirely, dimensions included and
  # deliberately so.
  def update_with_facts(attributes)
    transaction do
      return false unless update(attributes)

      # Sliced to `FACTS`, which is also what keeps `author_id` and
      # `update_reason` off the build: both are `attr_accessor`s for
      # paper_trail's meta rather than columns, and the admin controller merges
      # them into the same hash.
      facts_attributes = attributes.to_h.symbolize_keys.slice(*ModelBuild::FACTS)

      # Reloaded rather than read off the association: validating the row above
      # consults a fact reader, which caches whatever the build was at that
      # moment -- a nil, for a row whose build is written afterwards.
      reload_build&.update!(facts_attributes) if facts_attributes.present?

      true
    end
  end

  # One fact, for a query rather than a reader.
  #
  # A correlated subquery rather than the joined alias the other three catalogues
  # use, because Model is the one whose facts are reached **without** a join:
  # `Vehicle` sorts by `modelMass`, `modelScmSpeed`, `modelMaxSpeed` and
  # `modelGroundMaxSpeed` through its `model` association, and ransack builds
  # that join itself. An expression naming an alias nobody joined raises
  # `PG::UndefinedTable` -- measured, on the hangar.
  #
  # The `COALESCE` the other catalogues avoid is unavoidable here for the same
  # reason build existence cannot be this catalogue's filter: 31 of 246 models
  # are concept ships no build describes, and a filter that dropped them would
  # empty the catalogue of everything not yet flying.
  #
  # It is affordable because the subquery resolves at most one row per *model*,
  # not per result row -- Postgres memoizes on `vehicles.model_id`. Measured
  # against the columns on the largest sets in the database: the biggest hangar
  # (5,992 vehicles) 0.69ms against 1.09ms, the biggest fleet (9,598) 1.32ms
  # against 0.56ms, the models list 0.48ms against 0.30ms.
  def self.fact_sql(fact, source = ::ScData::Source.current)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      COALESCE(
        (SELECT model_facts.#{fact} FROM model_builds model_facts
          WHERE model_facts.model_id = models.id
            AND model_facts.environment = ?
            AND model_facts.version = ?),
        models.#{fact}
      )
    SQL
  end

  # Filtering and sorting read the build. Each shadows a real column of the same
  # name -- a ransacker wins over a column -- so every query parameter keeps
  # working untouched, with no API and no frontend change.
  ModelBuild::FILTERABLE.each do |fact|
    ransacker(fact) { Arel.sql(Model.fact_sql(fact)) }
  end

  # The column still answers for a model no build describes -- every concept ship,
  # and every ship the export dropped before this table existed.
  ModelBuild::FACTS.each do |fact|
    define_method(fact) do
      value = facts&.public_send(fact)

      value.nil? ? super() : value
    end
  end

  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :components, through: :hardpoints

  has_many :model_hardpoints,
    dependent: :destroy,
    autosave: true
  has_many :hardpoint_components, through: :model_hardpoints
  has_many :vehicles, dependent: :destroy

  has_many :module_hardpoints, dependent: :destroy
  has_many :modules,
    through: :module_hardpoints,
    source: :model_module

  has_many :module_packages,
    class_name: "ModelModulePackage",
    dependent: :destroy

  has_many :model_loaners,
    -> { where(hidden: false) },
    dependent: :destroy,
    inverse_of: :model
  has_many :loaners,
    through: :model_loaners,
    source: :loaner_model

  has_many :upgrade_kits, dependent: :destroy
  has_many :upgrades,
    through: :upgrade_kits,
    source: :model_upgrade

  has_many :paints,
    class_name: "ModelPaint",
    dependent: :destroy,
    inverse_of: :model

  has_many :sales,
    class_name: "ModelSale",
    dependent: :destroy,
    inverse_of: :model

  has_many :build_changes,
    class_name: "ModelBuildChange",
    dependent: :destroy,
    inverse_of: :model

  has_many :images,
    as: :gallery,
    dependent: :destroy,
    inverse_of: :gallery

  has_many :videos,
    dependent: :destroy

  has_many :model_snub_crafts,
    dependent: :destroy,
    inverse_of: :model

  has_many :snub_crafts,
    through: :model_snub_crafts,
    source: :snub_craft

  has_many :item_prices, as: :item, dependent: :destroy

  has_many :model_positions, dependent: :destroy

  has_many :docks, dependent: :destroy

  has_many :cargo_holds_db, class_name: "CargoHold", as: :parent, dependent: :destroy
  has_many :cargo_hold_container_capacities, through: :cargo_holds_db

  # Everything `api/v1/models/_base.jbuilder` reaches for, in one place, because
  # a list endpoint that misses a piece pays for it once per row. The hangar
  # renders that partial for every vehicle, so it wants this nested under
  # `:model` and is the reason this is shared rather than inlined in a scope.
  #
  # `loaners` is named even though `model_loaners` is: they are different
  # associations, and preloading one leaves the other to query per row. The
  # manufacturer brings its own pictures, because its partial renders them.
  def self.rendered_associations
    [
      # Both, because every mechanics reader consults `build || last_build`.
      # Without them a ship list is two extra queries per row rather than two
      # for the page -- and the ships and hangar endpoints are the slow ones.
      :build, :last_build,
      :item_prices, :loaners, :cargo_holds_db,
      {manufacturer: Manufacturer.attachment_preloads},
      {model_loaners: :loaner_model}
    ] + attachment_preloads
  end

  enum :dock_size,
    Dock.ship_sizes.keys.map(&:to_sym)

  serialize :cargo_holds, coder: YAML
  serialize :quantum_fuel_tanks, coder: YAML
  serialize :hydrogen_fuel_tanks, coder: YAML
  serialize :external_fuel_tanks, coder: YAML
  serialize :refuel_boom, coder: YAML

  accepts_nested_attributes_for :videos, allow_destroy: true
  accepts_nested_attributes_for :docks, allow_destroy: true

  has_one_attached :store_image
  has_one_attached :rsi_store_image
  has_one_attached :fleetchart_image
  has_one_attached :top_view
  has_one_attached :side_view
  has_one_attached :front_view
  has_one_attached :angled_view
  has_one_attached :top_view_colored
  has_one_attached :side_view_colored
  has_one_attached :front_view_colored
  has_one_attached :angled_view_colored
  has_one_attached :brochure
  has_one_attached :holo
  has_one_attached :extended_holo
  has_one_attached :extended_top_view
  has_one_attached :extended_side_view
  has_one_attached :extended_front_view
  has_one_attached :extended_angled_view
  has_one_attached :extended_top_view_colored
  has_one_attached :extended_side_view_colored
  has_one_attached :extended_front_view_colored
  has_one_attached :extended_angled_view_colored

  # The fleetchart sizes a ship from the pixel dimensions of the view it draws,
  # so transparent padding around the hull reads as part of the ship. The store
  # images are left alone: they are framed artwork, not measured against
  # anything. See AttachmentTrimmer.
  trim_attachment :top_view, :side_view, :front_view, :angled_view,
    :top_view_colored, :side_view_colored, :front_view_colored, :angled_view_colored,
    :extended_top_view, :extended_side_view, :extended_front_view, :extended_angled_view,
    :extended_top_view_colored, :extended_side_view_colored,
    :extended_front_view_colored, :extended_angled_view_colored

  before_save :update_slugs

  before_save :update_from_hardpoints
  before_create :set_last_updated_at

  after_save :send_on_sale_notification, if: :saved_change_to_on_sale?
  after_save :record_sale, if: :saved_change_to_on_sale?
  after_save :broadcast_update
  after_save :send_new_model_notification, if: :saved_change_to_rsi_id?

  validates :name, presence: true, uniqueness: {scope: :manufacturer_id}

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc", "createdAt asc", "createdAt desc", "length asc", "length desc",
    "beam asc", "beam desc", "height asc", "height desc", "mass asc", "mass desc", "cargo asc",
    "cargo desc", "manufacturerName asc", "manufacturerName desc", "pledgePrice asc",
    "pledgePrice desc", "price asc", "price desc", "scmSpeed asc", "scmSpeed desc", "maxSpeed asc",
    "maxSpeed desc", "groundMaxSpeed asc", "groundMaxSpeed desc", "productionStatus asc",
    "productionStatus desc", "focus asc", "focus desc", "rsiId asc", "rsiId desc"
  ]

  ransack_alias :manufacturer, :manufacturer_slug
  ransack_alias :search, :name_or_slug_or_manufacturer_slug

  ransack_attachment :front_view, :fleetchart_image, :top_view_colored, :holo

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "base_model_id",
      "beam", "cargo", "cargo_holds", "classification", "created_at", "description",
      "dock_size", "erkul_identifier", "fleetchart_image",
      "fleetchart_offset_length", "focus", "front_view",
      "ground", "ground_acceleration",
      "ground_decceleration", "ground_max_speed", "ground_reverse_speed", "height", "hidden",
      "holo", "holo_colored", "hydrogen_fuel_tank_size", "hydrogen_fuel_tanks", "id", "id_value", "in_game",
      "images_count", "last_updated_at", "length", "loaners_count",
      "manufacturer", "manufacturer_id", "mass", "max_crew", "max_speed", "min_crew", "model_paints_count", "module_hardpoints_count",
      "name", "notified", "on_sale", "personal_inventory", "pitch", "player_ownable", "pledge_price", "price", "production_note",
      "production_status", "quantum_fuel_tank_size", "quantum_fuel_tanks", "roll", "rsi_beam",
      "rsi_cargo", "rsi_chassis_id", "rsi_classification", "rsi_description", "rsi_focus",
      "rsi_height", "rsi_id", "rsi_length", "rsi_mass", "rsi_max_crew", "rsi_max_speed",
      "rsi_min_crew", "rsi_name", "rsi_pitch", "rsi_roll", "rsi_scm_speed", "rsi_size", "rsi_slug",
      "rsi_store_url", "rsi_yaw", "sales_page_url", "sc_beam", "sc_height",
      "sc_length", "scm_speed", "search",
      "size", "slug", "store_images_updated_at", "store_url", "top_view_colored",
      "updated_at", "upgrade_kits_count", "videos_count", "yaw"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "components", "docks", "images", "loaners", "manufacturer", "model_hardpoints",
      "model_loaners", "model_snub_crafts", "module_hardpoints", "module_packages",
      "modules", "paints", "snub_crafts", "upgrade_kits", "upgrades", "vehicles",
      "versions", "videos"
    ]
  end

  def self.ordered_by_name
    order(name: :asc)
  end

  PRODUCTION_STATUSES = %w[in-concept in-production flight-ready].freeze

  def sc_data_identifier
    sc_key.presence || slug&.tr("-", "_")
  end

  def self.production_status_filters
    PRODUCTION_STATUSES.map do |item|
      Filter.new(
        category: "productionStatus",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.classification_filters
    Model.classifications.map do |item|
      Filter.new(
        category: "classification",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.dock_size_filters
    Model.dock_sizes.map do |key, item|
      Filter.new(
        category: "dock_size",
        label: key.humanize,
        value: item
      )
    end
  end

  def self.classifications
    Model.visible.active.order(classification: :asc).all.map(&:classification).compact_blank.compact.uniq
  end

  def self.focus_filters(classification: nil)
    scope = Model.visible.active
    scope = scope.where(classification: classification) if classification.present?
    scope.map(&:focus).compact_blank.compact.uniq.map do |item|
      Filter.new(
        category: "focus",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.size_filters
    %w[vehicle snub small medium large extra_large capital].map do |item|
      Filter.new(
        category: "size",
        label: item.humanize,
        value: item
      )
    end
  end

  def self.year(year)
    where("created_at <= ? AND created_at >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  def self.with_dock
    includes(:docks).where.not(docks: {model_id: nil})
  end

  def update_from_hardpoints
    set_cargo_from_hardpoints
    set_quantum_fuel_from_hardpoints
    set_hydrogen_fuel_from_hardpoints
  end

  def set_cargo_from_hardpoints
    return if cargo_holds.blank? || (cargo.present? && !cargo.zero? && !cargo_holds_change_to_be_saved)

    self.cargo = cargo_holds.sum do |cargo_hold|
      cargo_hold.dig("capacity")&.to_f || 0
    end

    update_cargo_holds_db
  end

  def set_quantum_fuel_from_hardpoints
    return if quantum_fuel_tanks.blank? || (quantum_fuel_tank_size.present? && !quantum_fuel_tanks_change_to_be_saved)

    self.quantum_fuel_tank_size = quantum_fuel_tanks.sum do |item|
      item["capacity"]
    end
  end

  def set_hydrogen_fuel_from_hardpoints
    return if hydrogen_fuel_tanks.blank? || (hydrogen_fuel_tank_size.present? && !hydrogen_fuel_tanks_change_to_be_saved)

    self.hydrogen_fuel_tank_size = hydrogen_fuel_tanks.sum do |item|
      item["capacity"]
    end
  end

  # What the ship can do with its thrusters, in m/s^2. Main thrusters push it
  # forward, retro thrusters stop it, and the export gives every thruster a
  # `thrust_capacity` in newtons -- so with a mass this is Newton's second law and
  # nothing more.
  #
  # This replaces four columns that claimed to be accelerations and held
  # **seconds**: the Razor's old `scm_speed_acceleration` of 1.41 is the time it
  # takes to reach SCM speed, which is `scm_speed / main_acceleration`. Every
  # figure those columns expressed still follows from these two and a speed the
  # model already carries, and these say what they hold.
  def accelerations_from_hardpoints
    thrust = {"Main" => 0.0, "Retro" => 0.0}

    thruster_components.each do |data|
      next unless thrust.key?(data["thruster_type"])

      thrust[data["thruster_type"]] += data["thrust_capacity"].to_f
    end

    weight = read_attribute(:mass).to_f

    # Nothing to say rather than zero. A stored 0 claims the ship cannot move; a
    # nil says we do not know -- which is the truth for a catalogue loaded before
    # the export named `thruster_type`, and for a ship with no thrusters fitted.
    return {} if weight.zero? || thrust.values.sum.zero?

    {
      main_acceleration: (thrust["Main"] / weight).round(2),
      retro_acceleration: (thrust["Retro"] / weight).round(2)
    }
  end

  # Every thruster the loadout fits, as the export described it.
  #
  # A component whose `type_data` cannot be deserialized is skipped rather than
  # raised on. Those exist: a loader version wrote them as
  # `HashWithIndifferentAccess`, which the YAML coder's safe load refuses to read
  # back, and a single one of them would otherwise take down a whole load. Every
  # load rewrites the column, so they heal rather than accumulate.
  private def thruster_components
    hardpoints.includes(:component).where(group: :thruster).filter_map do |hardpoint|
      next if hardpoint.component.blank?

      begin
        data = hardpoint.component.type_data
      rescue Psych::Exception
        next
      end

      data if data.is_a?(Hash)
    end
  end

  public

  # Seconds from a standstill to SCM speed, and from SCM speed back to one. Not
  # stored: they are the two facts above against a speed already on the record,
  # and storing them would be the same number written twice.
  def seconds_to_scm_speed
    seconds_for(scm_speed, main_acceleration)
  end

  def seconds_to_stop_from_scm_speed
    seconds_for(scm_speed, retro_acceleration)
  end

  def seconds_to_max_speed
    seconds_for(max_speed, main_acceleration)
  end

  private def seconds_for(speed, acceleration)
    return if speed.blank? || acceleration.blank? || acceleration.to_f.zero?

    (speed.to_f / acceleration.to_f).round(2)
  end

  public

  # Returns rather than assigns, so the loader can put it through `update_params`
  # like every other game-file fact and it reaches the build as well as the row.
  # Assigning it here is what kept it out of both.
  def fuel_consumption_from_hardpoints
    thrusters = thruster_components

    thrusters.sum do |thruster|
      thruster.dig("fuel_burn_rate_per10_k_newton").to_f
    end
  end

  def rsi_store_url
    "#{Rails.configuration.rsi.endpoint}#{store_url}"
  end

  def rsi_sales_page_url
    return if sales_page_url.blank?

    "#{Rails.configuration.rsi.endpoint}#{sales_page_url}"
  end

  def sold_at
    item_prices.select(&:sell?).sort_by(&:price).uniq(&:location)
  end

  def bought_at
    item_prices.select(&:buy?).sort_by(&:price).uniq(&:location)
  end

  def rental_at
    item_prices.select(&:rental?).sort_by(&:price).uniq(&:location)
  end

  def dock_counts
    docks.to_a.group_by(&:ship_size).map do |size, docks_by_size|
      docks_by_size.group_by(&:dock_type).map do |dock_type, docks_by_type|
        DockCount.new(dock_size: size, dock_type:, dock_type_label: docks_by_type.first.dock_type_label, dock_count: docks_by_type.size)
      end
    end.flatten
  end

  def variants
    if base_model_id.present?
      Model.where(base_model_id:).where.not(id:).where.not(base_model_id: nil)
    else
      Model.where(rsi_chassis_id:).where.not(id:).where.not(rsi_chassis_id: nil)
    end
  end

  def in_hangar(user)
    return if user.blank?

    user.models.exists?(id)
  end

  def random_image
    images.enabled.background.order(Arel.sql("RANDOM()")).first
  end

  def cargo_label
    return if cargo.blank? || cargo.zero?

    number = number_with_precision(
      cargo,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "SCU"].join(" ")
  end

  # The ship's own storage container, which the game keeps apart from the cargo
  # grid: it holds personal gear rather than freight, and most ships measure it
  # in fractions of an SCU.
  def personal_inventory_label
    return if personal_inventory.blank? || personal_inventory.zero?

    number = number_with_precision(
      personal_inventory,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "SCU"].join(" ")
  end

  def length_label
    return if length.blank? || length.zero?

    number = number_with_precision(
      length,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def beam_label
    return if beam.blank? || beam.zero?

    number = number_with_precision(
      beam,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def height_label
    return if height.blank? || height.zero?

    number = number_with_precision(
      height,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def extended_length_label
    return if extended_length.blank? || extended_length.zero?

    number = number_with_precision(
      extended_length,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def extended_beam_label
    return if extended_beam.blank? || extended_beam.zero?

    number = number_with_precision(
      extended_beam,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def extended_height_label
    return if extended_height.blank? || extended_height.zero?

    number = number_with_precision(
      extended_height,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "m"].join(" ")
  end

  def price_label
    return if price.blank? || price.zero?

    number = number_with_precision(
      price,
      precision: 2,
      strip_insignificant_zeros: true
    )

    [number, "aUEC"].join(" ")
  end

  def pledge_price_label
    return if pledge_price.blank? || pledge_price.zero?

    number_to_currency(
      pledge_price,
      precision: 2,
      strip_insignificant_zeros: true
    )
  end

  def to_json(*_args)
    to_jbuilder_json
  end

  def url
    api_v1_model_url(slug:)
  end

  def frontend_url
    frontend_model_url(slug:)
  end

  def hangar_link_slug
    return legacy_slug if legacy_slug.present?

    prefix = "#{manufacturer&.code&.downcase}-"
    slug&.start_with?(prefix) ? slug.delete_prefix(prefix) : slug
  end

  def last_sale
    sales.recent_first.first
  end

  def sales_count
    sales.count
  end

  # Needs two sales to have a gap at all. Measured start to start, so a long
  # sale does not read as a short wait for the next one.
  def average_days_between_sales
    started_ats = sales.order(:started_at).pluck(:started_at)
    return if started_ats.size < 2

    gaps = started_ats.each_cons(2).map { |before, after| (after - before) / 1.day }

    (gaps.sum / gaps.size).round(1)
  end

  private def broadcast_update
    ActionCable.server.broadcast("models", to_jbuilder_hash)
  end

  private def send_new_model_notification
    return if notified? || hidden? || rsi_id.blank?

    Notifications::NewModelJob.perform_async(id)

    ActionCable.server.broadcast("new_model", to_jbuilder_hash)
  end

  # The flag alone says only whether a ship is on sale right now. Turning each
  # flip into a row is what makes "how often" and "how long ago" answerable --
  # and it only works forwards, since nothing recorded the flips before this.
  private def record_sale
    if on_sale?
      sales.create!(started_at: Time.current) unless sales.ongoing.exists?
    else
      sales.ongoing.update_all(ended_at: Time.current, updated_at: Time.current)
    end
  end

  private def send_on_sale_notification
    return unless on_sale?
    return if created_at > 24.hours.ago

    Notifications::ModelOnSaleJob.perform_async(id)

    ActionCable.server.broadcast("on_sale", to_jbuilder_hash)
  end

  private def update_slugs
    self.rsi_slug = rsi_name&.parameterize.presence
    if manufacturer&.code.present?
      self.slug = "#{manufacturer.code.downcase}-#{name.parameterize}"
    else
      super
    end
  end

  private def set_last_updated_at
    return if last_updated_at.present?

    self.last_updated_at = Time.zone.now
  end
end
