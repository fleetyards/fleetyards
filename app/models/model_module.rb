# frozen_string_literal: true

# == Schema Information
#
# Table name: model_modules
#
#  id                :uuid             not null, primary key
#  active            :boolean          default(TRUE)
#  cargo             :decimal(15, 2)
#  cargo_holds       :string
#  description       :text
#  hidden            :boolean          default(TRUE)
#  name              :string
#  pledge_price      :decimal(15, 2)
#  price             :decimal(15, 2)
#  production_status :string
#  sc_key            :string
#  slug              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  manufacturer_id   :uuid
#
class ModelModule < ApplicationRecord
  include ActiveStorageVariants
  include DerivedCargoHolds

  paginates_per 30

  attr_accessor :update_reason, :update_reason_description, :author_id

  has_paper_trail on: %i[update], only: %i[
    min_size max_size component_id cargo cargo_holds
  ], meta: {
    author_id: :author_id,
    reason: :update_reason,
    reason_description: :update_reason_description
  }

  belongs_to :manufacturer, optional: true

  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :components, through: :hardpoints

  has_many :module_hardpoints,
    dependent: :destroy
  has_many :models, through: :module_hardpoints
  has_many :model_module_package_items, dependent: :destroy
  has_many :model_module_packages, through: :model_module_package_items

  has_many :item_prices, as: :item, dependent: :destroy

  has_many :cargo_holds_db, class_name: "CargoHold", as: :parent, dependent: :destroy
  has_many :docks, as: :parent, dependent: :destroy

  serialize :cargo_holds, coder: YAML

  # What each build of the game says about this module. Written alongside the
  # columns, so the reads can move over in their own step.
  has_many :builds, class_name: "ModelModuleBuild", dependent: :destroy
  has_one :build, -> { current }, class_name: "ModelModuleBuild", inverse_of: :model_module

  # The modules a build describes, plus -- while this environment has no build
  # rows at all -- everything. That last clause is the window between this table
  # shipping and its backfill running, and it is asked of the environment rather
  # than of the module for the same reason `Hardpoint.in_build` asks that way: a
  # module retired from a build loses its row for it, and prune_builds drops the
  # older ones, so a per-module version would let a module that left the game
  # quietly reappear.
  #
  # A module with no `sc_key` is never described by a build -- the loader only
  # walks keyed ones -- and has to stay offered regardless: those are the
  # RSI-store modules Fleetyards knows about and the game files do not.
  IN_BUILD_SQL = <<~SQL.squish
    model_modules.sc_key IS NULL
    OR EXISTS (
      SELECT 1 FROM model_module_builds
       WHERE model_module_builds.model_module_id = model_modules.id
         AND model_module_builds.environment = :environment
         AND model_module_builds.version = :version
    )
    OR NOT EXISTS (
      SELECT 1 FROM model_module_builds WHERE model_module_builds.environment = :environment
    )
  SQL

  scope :in_build, ->(source = ::ScData::Source.current) {
    where(sanitize_sql_array([IN_BUILD_SQL, {environment: source.environment, version: source.version}]))
  }

  # Read through the build, falling back to the column. The column still answers
  # for a module no load has given a build -- an RSI-store module the game files
  # do not name, or one an admin filled in by hand.
  ModelModuleBuild::READ_THROUGH.each do |fact|
    define_method(fact) do
      value = build&.public_send(fact)

      value.nil? ? super() : value
    end
  end

  has_one_attached :store_image

  accepts_nested_attributes_for :module_hardpoints, allow_destroy: true

  before_save :update_slugs
  before_save :update_from_hardpoints

  after_save :touch_models

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "created_at", "description", "hidden", "id", "id_value", "manufacturer_id",
      "name", "pledge_price", "production_status", "slug", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "manufacturer", "model_module_packge_items", "model_module_packges", "models",
      "module_hardpoints", "shop_commodities"
    ]
  end

  def self.ordered_by_name
    order(name: :asc)
  end

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  def sold_at
    item_prices.sell.order(price: :asc).uniq(&:location)
  end

  def bought_at
    item_prices.buy.order(price: :asc).uniq(&:location)
  end

  def update_from_hardpoints
    set_cargo_from_hardpoints
  end

  def set_cargo_from_hardpoints
    return if cargo_holds.blank? || (cargo.present? && !cargo_holds_change_to_be_saved)

    self.cargo = cargo_holds.sum do |cargo_hold|
      cargo_hold["capacity"]&.to_f || 0
    end

    update_cargo_holds_db
  end

  private def touch_models
    # rubocop:disable Rails/SkipsModelValidations
    models.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
