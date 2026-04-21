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

  serialize :cargo_holds, coder: YAML

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

  def cargo_holds_with_offsets
    db_records = cargo_holds_db.where.not(offset_x: nil)
      .or(cargo_holds_db.where.not(offset_y: nil))
      .or(cargo_holds_db.where.not(offset_z: nil))
      .or(cargo_holds_db.where.not(rotation: nil))
      .index_by(&:position)

    return cargo_holds if db_records.empty?

    cargo_holds.each_with_index.map do |hold_data, index|
      db_record = db_records[index]
      if db_record
        extra = {
          "offset" => {
            "x" => db_record.offset_x&.to_f || 0.0,
            "y" => db_record.offset_y&.to_f || 0.0,
            "z" => db_record.offset_z&.to_f || 0.0
          }
        }
        extra["rotation"] = db_record.rotation if db_record.rotation.present?
        hold_data.merge(extra)
      else
        hold_data
      end
    end
  end

  def update_cargo_holds_db
    existing_offsets = cargo_holds_db.where.not(offset_x: nil).or(
      cargo_holds_db.where.not(offset_y: nil)
    ).or(
      cargo_holds_db.where.not(offset_z: nil)
    ).or(
      cargo_holds_db.where.not(rotation: nil)
    ).index_by(&:position)

    cargo_holds_db.destroy_all

    cargo_holds.each_with_index do |hold_data, index|
      next if hold_data.blank? || hold_data["dimensions"].blank?

      previous = existing_offsets[index]

      cargo_hold = cargo_holds_db.create!(
        name: hold_data["name"],
        dimension_x: hold_data["dimensions"]["x"],
        dimension_y: hold_data["dimensions"]["y"],
        dimension_z: hold_data["dimensions"]["z"],
        capacity_scu: hold_data["capacity"],
        max_container_size_scu: hold_data.dig("max_container_size", "size"),
        max_container_dimension_x: hold_data.dig("max_container_size", "dimensions", "x"),
        max_container_dimension_y: hold_data.dig("max_container_size", "dimensions", "y"),
        max_container_dimension_z: hold_data.dig("max_container_size", "dimensions", "z"),
        min_container_size_scu: hold_data.dig("limits", "min", "capacity"),
        min_container_dimension_x: hold_data.dig("limits", "min", "dimensions", "x"),
        min_container_dimension_y: hold_data.dig("limits", "min", "dimensions", "y"),
        min_container_dimension_z: hold_data.dig("limits", "min", "dimensions", "z"),
        position: index,
        offset_x: previous&.offset_x,
        offset_y: previous&.offset_y,
        offset_z: previous&.offset_z,
        rotation: previous&.rotation
      )

      cargo_hold.calculate_container_capacities!
    end
  end

  private def touch_models
    # rubocop:disable Rails/SkipsModelValidations
    models.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
