# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id                       :uuid             not null, primary key
#  active                   :boolean          default(TRUE)
#  afterburner_ground_speed :decimal(15, 2)
#  afterburner_speed        :decimal(15, 2)
#  angled_view              :string
#  angled_view_height       :integer
#  angled_view_width        :integer
#  beam                     :decimal(15, 2)   default(0.0), not null
#  brochure                 :string
#  cargo                    :decimal(15, 2)
#  cargo_holds              :string
#  classification           :string(255)
#  cruise_speed             :decimal(15, 2)
#  description              :text
#  dock_size                :integer
#  erkul_identifier         :string
#  fleetchart_image         :string
#  fleetchart_image_height  :integer
#  fleetchart_image_width   :integer
#  fleetchart_offset_length :decimal(15, 2)
#  focus                    :string(255)
#  ground                   :boolean          default(FALSE)
#  ground_speed             :decimal(15, 2)
#  height                   :decimal(15, 2)   default(0.0), not null
#  hidden                   :boolean          default(TRUE)
#  holo                     :string
#  holo_colored             :boolean          default(FALSE)
#  hydrogen_fuel_tank_size  :decimal(15, 2)
#  hydrogen_fuel_tanks      :string
#  images_count             :integer          default(0)
#  last_pledge_price        :decimal(15, 2)
#  last_updated_at          :datetime
#  length                   :decimal(15, 2)   default(0.0), not null
#  mass                     :decimal(15, 2)   default(0.0), not null
#  max_crew                 :integer
#  max_speed                :decimal(15, 2)
#  min_crew                 :integer
#  model_paints_count       :integer          default(0)
#  module_hardpoints_count  :integer          default(0)
#  name                     :string(255)
#  name_slug                :string
#  notified                 :boolean          default(FALSE)
#  on_sale                  :boolean          default(FALSE)
#  pitch_max                :decimal(15, 2)
#  pledge_price             :decimal(15, 2)
#  price                    :decimal(15, 2)
#  production_note          :string(255)
#  production_status        :string(255)
#  quantum_fuel_tank_size   :decimal(15, 2)
#  quantum_fuel_tanks       :string
#  roll_max                 :decimal(15, 2)
#  rsi_afterburner_speed    :decimal(15, 2)
#  rsi_beam                 :decimal(15, 2)   default(0.0), not null
#  rsi_cargo                :decimal(15, 2)
#  rsi_classification       :string
#  rsi_description          :text
#  rsi_focus                :string
#  rsi_height               :decimal(15, 2)   default(0.0), not null
#  rsi_length               :decimal(15, 2)   default(0.0), not null
#  rsi_mass                 :decimal(15, 2)   default(0.0), not null
#  rsi_max_crew             :integer
#  rsi_min_crew             :integer
#  rsi_name                 :string
#  rsi_pitch_max            :decimal(15, 2)
#  rsi_roll_max             :decimal(15, 2)
#  rsi_scm_speed            :decimal(15, 2)
#  rsi_size                 :string
#  rsi_slug                 :string
#  rsi_store_image          :string
#  rsi_store_url            :string
#  rsi_xaxis_acceleration   :decimal(15, 2)
#  rsi_yaw_max              :decimal(15, 2)
#  rsi_yaxis_acceleration   :decimal(15, 2)
#  rsi_zaxis_acceleration   :decimal(15, 2)
#  sales_page_url           :string
#  sc_identifier            :string
#  scm_speed                :decimal(15, 2)
#  side_view                :string
#  side_view_height         :integer
#  side_view_width          :integer
#  size                     :string
#  slug                     :string(255)
#  speed                    :decimal(15, 2)
#  store_image              :string(255)
#  store_images_updated_at  :datetime
#  store_url                :string(255)
#  top_view                 :string
#  top_view_height          :integer
#  top_view_width           :integer
#  upgrade_kits_count       :integer          default(0)
#  videos_count             :integer          default(0)
#  xaxis_acceleration       :decimal(15, 2)
#  yaw_max                  :decimal(15, 2)
#  yaxis_acceleration       :decimal(15, 2)
#  zaxis_acceleration       :decimal(15, 2)
#  created_at               :datetime
#  updated_at               :datetime
#  base_model_id            :uuid
#  manufacturer_id          :uuid
#  rsi_chassis_id           :integer
#  rsi_id                   :integer
#
# Indexes
#
#  index_models_on_base_model_id  (base_model_id)
#
class Model < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  paginates_per 30
  max_paginates_per 240

  PAGINATION_OPTIONS = [15, 30, 60, 120, 240].freeze

  searchkick searchable: %i[name manufacturer_name manufacturer_code],
             word_start: %i[name manufacturer_name]

  def search_data
    {
      name: name,
      manufacturer_name: manufacturer.name,
      manufacturer_code: manufacturer.code
    }
  end

  def should_index?
    active && !hidden
  end

  belongs_to :manufacturer, optional: true

  has_one :addition,
          class_name: 'ModelAddition',
          dependent: :destroy,
          inverse_of: :model

  delegate :net_cargo, to: :addition, allow_nil: true
  delegate :height, :length, :cargo, :max_crew, :min_crew,
           :scm_speed, :afterburner_speed, :mass, :beam, :price, to: :addition, allow_nil: true, prefix: true

  accepts_nested_attributes_for :addition, allow_destroy: true

  has_many :model_hardpoints,
           dependent: :destroy,
           autosave: true
  has_many :vehicles, dependent: :destroy
  has_many :components, through: :model_hardpoints

  has_many :module_hardpoints, dependent: :destroy
  has_many :modules,
           through: :module_hardpoints,
           source: :model_module

  has_many :module_packages,
           class_name: 'ModelModulePackage',
           dependent: :destroy

  has_many :model_loaners,
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
           class_name: 'ModelPaint',
           dependent: :destroy,
           inverse_of: :model

  has_many :images,
           as: :gallery,
           dependent: :destroy,
           inverse_of: :gallery

  has_many :videos,
           dependent: :destroy

  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  has_many :docks, dependent: :destroy

  enum dock_size: Dock.ship_sizes.keys.map(&:to_sym)

  serialize :cargo_holds
  serialize :quantum_fuel_tanks
  serialize :hydrogen_fuel_tanks

  accepts_nested_attributes_for :videos, allow_destroy: true
  accepts_nested_attributes_for :docks, allow_destroy: true

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :rsi_store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader
  mount_uploader :top_view, FleetchartImageUploader
  mount_uploader :side_view, FleetchartImageUploader
  mount_uploader :angled_view, FleetchartImageUploader
  mount_uploader :brochure, BrochureUploader
  mount_uploader :holo, HoloUploader

  before_save :update_slugs

  before_save :update_from_hardpoints
  before_create :set_last_updated_at

  after_save :touch_shop_commodities
  after_save :send_on_sale_notification, if: :saved_change_to_on_sale?
  after_save :broadcast_update
  after_save :send_new_model_notification

  ransack_alias :name, :name_or_slug_or_manufacturer_slug
  ransack_alias :manufacturer, :manufacturer_slug
  ransack_alias :search, :name_or_slug_or_manufacturer_slug

  def self.ordered_by_name
    order(name: :asc)
  end

  def self.production_status_filters
    Model.visible.active.all.map(&:production_status).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'productionStatus',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.classification_filters
    Model.classifications.map do |item|
      Filter.new(
        category: 'classification',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.classifications
    Model.visible.active.order(classification: :asc).all.map(&:classification).reject(&:blank?).compact.uniq
  end

  def self.focus_filters
    Model.visible.active.all.map(&:focus).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'focus',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.size_filters
    %w[vehicle snub small medium large extra_large capital].map do |item|
      Filter.new(
        category: 'size',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.year(year)
    where('created_at <= ? AND created_at >= ?', "#{year}-12-31", "#{year}-01-01")
  end

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  def self.with_dock
    includes(:docks).where.not(docks: { model_id: nil })
  end

  def update_from_hardpoints
    set_cargo_from_hardpoints
    set_quantum_fuel_from_hardpoints
    set_hydrogen_fuel_from_hardpoints
  end

  def set_cargo_from_hardpoints
    return if cargo_holds.blank? || (cargo.present? && !cargo_holds_change_to_be_saved)

    self.cargo = cargo_holds.sum do |item|
      item[:scu]
    end
  end

  def set_quantum_fuel_from_hardpoints
    return if quantum_fuel_tanks.blank? || (quantum_fuel_tank_size.present? && !quantum_fuel_tanks_change_to_be_saved)

    self.quantum_fuel_tank_size = quantum_fuel_tanks.sum do |item|
      item[:capacity]
    end
  end

  def set_hydrogen_fuel_from_hardpoints
    return if hydrogen_fuel_tanks.blank? || (hydrogen_fuel_tank_size.present? && !hydrogen_fuel_tanks_change_to_be_saved)

    self.hydrogen_fuel_tank_size = hydrogen_fuel_tanks.sum do |item|
      item[:capacity]
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
    shop_commodities.where.not(sell_price: nil).order(sell_price: :asc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).order(buy_price: :desc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def listed_at
    shop_commodities.where(sell_price: nil, buy_price: nil).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def rental_at
    shop_commodities.where.not(rental_price_1_day: nil).order(rental_price_1_day: :asc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def dock_counts
    docks.to_a.group_by(&:ship_size).map do |size, docks_by_size|
      docks_by_size.group_by(&:dock_type).map do |dock_type, docks_by_type|
        DockCount.new(dock_size: size, dock_type: dock_type, dock_type_label: docks_by_type.first.dock_type_label, dock_count: docks_by_type.size)
      end
    end.flatten
  end

  def variants
    Model.where(rsi_chassis_id: rsi_chassis_id).where.not(id: id).where.not(rsi_chassis_id: nil)
  end

  def snub_crafts
    Model.where(
      'length <= :length and beam <= :beam and height <= :height',
      length: docks.map(&:length).max,
      beam: docks.map(&:beam).max,
      height: docks.map(&:height).max
    )
  end

  def in_hangar(user)
    return if user.blank?

    user.models.exists?(id)
  end

  def random_image
    images.enabled.background.order(Arel.sql('RANDOM()')).first
  end

  def cargo_label
    return if cargo.blank? || cargo.zero?

    human_cargo = number_with_precision(
      cargo,
      precision: 2,
      strip_insignificant_zeros: true
    )
    "#{name} (#{human_cargo} SCU)"
  end

  def to_json(*_args)
    to_jbuilder_json
  end

  private def broadcast_update
    ActionCable.server.broadcast('models', to_json)
  end

  private def send_new_model_notification
    return if notified? || hidden?

    Notifications::NewModelJob.perform_later(id)

    ActionCable.server.broadcast('new_model', to_json)
  end

  private def send_on_sale_notification
    return unless on_sale?
    return if created_at > Time.zone.now - 24.hours

    Notifications::ModelOnSaleJob.perform_later(id)

    ActionCable.server.broadcast('on_sale', to_json)
  end

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private def update_slugs
    super
    self.rsi_slug = SlugHelper.generate_slug(rsi_name)
  end

  private def set_last_updated_at
    return if last_updated_at.present?

    self.last_updated_at = Time.zone.now
  end
end
