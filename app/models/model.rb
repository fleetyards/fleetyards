# frozen_string_literal: true

class Model < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  paginates_per 30

  searchkick searchable: %i[name manufacturer_name manufacturer_code],
             word_start: %i[name manufacturer_name],
             filterable: []

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

  has_many :hardpoints,
           dependent: :destroy,
           autosave: true
  has_many :vehicles,
           dependent: :destroy
  has_many :components,
           through: :hardpoints

  has_many :module_hardpoints,
           dependent: :destroy
  has_many :modules,
           through: :module_hardpoints,
           source: :model_module

  has_many :upgrades,
           class_name: 'ModelUpgrade',
           dependent: :destroy,
           inverse_of: :model

  has_many :upgrade_kits,
           dependent: :destroy
  has_many :upgrades,
           through: :upgrade_kits,
           source: :model_upgrade

  has_many :images,
           as: :gallery,
           dependent: :destroy,
           inverse_of: :gallery

  has_many :videos,
           dependent: :destroy

  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  has_many :docks, dependent: :destroy

  enum dock_size: Dock.ship_sizes.keys.map(&:to_sym)

  accepts_nested_attributes_for :videos, allow_destroy: true
  accepts_nested_attributes_for :docks, allow_destroy: true

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader
  mount_uploader :brochure, BrochureUploader

  before_save :update_slugs
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
    Model.visible.active.all.map(&:classification).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'classification',
        name: item.humanize,
        value: item
      )
    end
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
    %w[vehicle snub small medium large capital].map do |item|
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

  def sold_at
    shop_commodities.where.not(sell_price: nil).uniq { |item| item.shop.slug }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).uniq { |item| item.shop.slug }
  end

  def rental_at
    shop_commodities.where.not(rent_price_1_day: nil).uniq { |item| item.shop.slug }
  end

  def dock_counts
    docks.to_a.group_by(&:ship_size).map do |size, docks_by_size|
      docks_by_size.group_by(&:dock_type).map do |dock_type, docks_by_type|
        OpenStruct.new(size: size, dock_type: dock_type, dock_type_label: docks_by_type.first.dock_type_label, count: docks_by_type.size)
      end
    end.flatten
  end

  def variants
    Model.where(rsi_chassis_id: rsi_chassis_id).where.not(id: id, rsi_chassis_id: nil)
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

    ModelNotificationWorker.perform_async(id)
  end

  private def send_on_sale_notification
    return unless on_sale?

    VehiclesWorker.perform_async(id)
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
