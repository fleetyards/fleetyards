# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                :uuid             not null, primary key
#  alternative_names :string
#  flagship          :boolean          default(FALSE)
#  hidden            :boolean          default(FALSE)
#  loaner            :boolean          default(FALSE)
#  name              :string(255)
#  name_visible      :boolean          default(FALSE)
#  notify            :boolean          default(TRUE)
#  public            :boolean          default(FALSE)
#  purchased         :boolean          default(FALSE)
#  sale_notify       :boolean          default(FALSE)
#  serial            :string
#  created_at        :datetime
#  updated_at        :datetime
#  model_id          :uuid
#  model_paint_id    :uuid
#  module_package_id :uuid
#  user_id           :uuid
#  vehicle_id        :uuid
#
# Indexes
#
#  index_vehicles_on_model_id            (model_id)
#  index_vehicles_on_serial_and_user_id  (serial,user_id) UNIQUE
#  index_vehicles_on_user_id             (user_id)
#
require 'csv'

class Vehicle < ApplicationRecord
  paginates_per 30
  max_paginates_per 240

  PAGINATION_OPTIONS = [15, 30, 60, 120, 240].freeze

  scope :visible, -> { where(hidden: false) }

  belongs_to :model
  belongs_to :model_paint, optional: true
  belongs_to :user
  belongs_to :module_package,
             class_name: 'ModelModulePackage',
             optional: true

  has_many :task_forces, dependent: :destroy
  has_many :hangar_groups, through: :task_forces
  has_many :public_hangar_groups,
           -> { where(public: true) },
           class_name: 'HangarGroup',
           source: :hangar_group,
           through: :task_forces

  has_many :vehicle_modules, dependent: :destroy
  has_many :model_modules, through: :vehicle_modules

  has_many :vehicle_upgrades, dependent: :destroy
  has_many :model_upgrades, through: :vehicle_upgrades

  validates :model_id, presence: true
  validates :serial, uniqueness: { scope: :user_id }, allow_nil: true

  NULL_ATTRS = %w[name serial].freeze

  before_validation :normalize_serial
  before_save :nil_if_blank
  before_save :set_module_package

  after_create :add_loaners, :broadcast_create
  after_destroy :remove_loaners, :broadcast_destroy
  after_save :set_flagship
  after_commit :broadcast_update
  after_touch :clear_association_cache

  ransack_alias :name, :name_or_model_name_or_model_slug
  ransack_alias :on_sale, :model_on_sale
  ransack_alias :length, :model_length
  ransack_alias :price, :model_price
  ransack_alias :pledge_price, :model_pledge_price
  ransack_alias :manufacturer, :model_manufacturer_slug
  ransack_alias :classification, :model_classification
  ransack_alias :focus, :model_focus
  ransack_alias :size, :model_size
  ransack_alias :production_status, :model_production_status
  ransack_alias :hangar_groups, :hangar_groups_slug

  serialize :alternative_names, Array

  def add_loaners
    return if loaner?

    model.loaners.each do |model_loaner|
      create_loaner(model_loaner)
    end
  end

  def remove_loaners
    return if loaner?

    Vehicle.where(loaner: true, vehicle_id: id, user_id: user_id).destroy_all

    Vehicle.where(loaner: true, user_id: user_id).find_each do |loaner_vehicle|
      loaner_vehicle.update(
        hidden: Vehicle.where(loaner: true, model_id: loaner_vehicle.model_id, user_id: user_id, hidden: false).where.not(id: loaner_vehicle.id).exists?
      )
    end
  end

  def create_loaner(model_loaner)
    Vehicle.create(
      loaner: true,
      model_id: model_loaner.id,
      user_id: user_id,
      vehicle_id: id,
      public: false,
      purchased: true,
      hidden: Vehicle.exists?(loaner: true, model_id: model_loaner.id, user_id: user_id)
    )
  end

  def broadcast_update
    return if loaner? || !notify?

    HangarChannel.broadcast_to(user, to_json)
  end

  def broadcast_create
    return if loaner? || !notify?

    HangarCreateChannel.broadcast_to(user, to_json)
  end

  def broadcast_destroy
    return if loaner? || !notify?

    HangarDestroyChannel.broadcast_to(user, to_json)
  end

  def self.purchased
    where(purchased: true)
  end

  def self.public
    where(public: true)
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

    Vehicle.where(user_id: user_id, flagship: true)
      .where.not(id: id)
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
      (package.model_module_ids - model_module_ids).size.zero?
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
