# frozen_string_literal: true

class Model < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  paginates_per 30

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

  accepts_nested_attributes_for :videos, allow_destroy: true

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader
  mount_uploader :brochure, BrochureUploader

  before_save :update_slugs
  before_create :set_last_updated_at

  after_save :touch_shop_commodities
  after_save :send_on_sale_notification, if: :saved_change_to_on_sale?
  after_save :broadcast_update
  after_save :send_new_model_notification

  ransack_alias :name, :name_or_slug
  ransack_alias :manufacturer, :manufacturer_slug

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

  %i[height beam length mass cargo min_crew price max_crew scm_speed afterburner_speed ground_speed afterburner_ground_speed].each do |method_name|
    define_method "display_#{method_name}" do
      display_value = try("fallback_#{method_name}")
      if display_value.present? && !display_value.zero?
        display_value
      else
        try(method_name)
      end
    end
  end

  def price
    ShopCommodity.where(commodity_item_type: 'Model', commodity_item_id: id)
                 .order(sell_price: :desc)
                 .first&.sell_price
  end

  def variants
    Model.where(rsi_chassis_id: rsi_chassis_id).where.not(id: id, rsi_chassis_id: nil)
  end

  def in_hangar(user)
    return if user.blank?

    user.models.exists?(id)
  end

  def on_sale_with_price?
    on_sale? && !price.zero?
  end

  def random_image
    images.enabled.background.order(Arel.sql('RANDOM()')).first
  end

  def human_display_cargo
    return if display_cargo.blank? || display_cargo.zero?

    number_with_precision(display_cargo, precision: 2, strip_insignificant_zeros: true)
  end

  def cargo_label
    return if display_cargo.blank? || display_cargo.zero?

    human_cargo = number_with_precision(
      display_cargo,
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
