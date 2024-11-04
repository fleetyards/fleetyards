# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                   :uuid             not null, primary key
#  alternative_names    :string
#  bought_via           :integer          default("pledge_store")
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
#  index_vehicles_on_model_id_and_id     (model_id,id)
#  index_vehicles_on_serial_and_user_id  (serial,user_id) UNIQUE
#  index_vehicles_on_user_id             (user_id)
#
require "csv"

class Vehicle < ApplicationRecord
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

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces
  has_many :public_hangar_groups,
    -> { where(public: true) },
    class_name: "HangarGroup",
    source: :hangar_group,
    through: :task_forces

  has_many :fleet_vehicles, dependent: :destroy

  has_many :vehicle_modules, dependent: :destroy
  has_many :model_modules, through: :vehicle_modules

  has_many :vehicle_upgrades, dependent: :destroy
  has_many :model_upgrades, through: :vehicle_upgrades

  validates :serial, uniqueness: {scope: :user_id}, allow_nil: true

  NULL_ATTRS = %w[name serial].freeze

  enum bought_via: {pledge_store: 0, ingame: 1}, _prefix: true

  before_validation :normalize_serial
  before_save :nil_if_blank
  before_save :set_module_package
  before_save :reset_pledge_id_if_wanted
  before_save :update_slugs

  after_create :broadcast_create
  after_destroy :remove_loaners, :broadcast_destroy
  after_save :set_flagship, :update_loaners, :reset_hangar_groups
  after_commit :broadcast_update, :schedule_fleet_vehicle_update

  DEFAULT_SORTING_PARAMS = ["flagship desc", "name asc", "model_name asc"]
  ALLOWED_SORTING_PARAMS = [
    "flagship desc", "flagship asc", "name asc", "name desc", "model_name asc", "model_name desc",
    "created_at asc", "created_at desc", "updated_at asc", "updated_at desc"
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
      "alternative_names", "beam", "bought_via", "classification", "created_at", "flagship",
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
        name: Vehicle.human_enum_name(:bought_via, item),
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
    user.fleet_memberships.each do |fleet_membership|
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
    existing_loaner = Vehicle.where(loaner: true, vehicle_id: id, model_id: model_loaner.id, wanted:, user_id:).first

    if existing_loaner.present?
      existing_loaner.update(hidden: Vehicle.exists?(loaner: true, model_id: model_loaner.id, wanted:, user_id:, hidden: false))

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

  def broadcast_update
    return if loaner? || !notify?

    WishlistChannel.broadcast_to(user, to_json)
    HangarChannel.broadcast_to(user, to_json)
  end

  def broadcast_create
    return if loaner? || !notify?

    if wanted?
      WishlistCreateChannel.broadcast_to(user, to_json)
    else
      HangarCreateChannel.broadcast_to(user, to_json)
    end
  end

  def broadcast_destroy
    return if loaner? || !notify?

    if wanted?
      WishlistDestroyChannel.broadcast_to(user, to_json)
    else
      HangarDestroyChannel.broadcast_to(user, to_json)
    end
  end

  def export_name
    return model_paint.rsi_name if model_paint.present? && model_paint.rsi_id.present?

    model.rsi_name || model.name
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

  def to_json(*_args)
    to_jbuilder_json
  end

  protected def normalize_serial
    return if serial.blank?

    self.serial = serial.upcase
  end

  protected def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
