# frozen_string_literal: true

class Model < ApplicationRecord
  belongs_to :manufacturer, required: false

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
  has_many :components,
           through: :hardpoints

  has_many :images,
           as: :gallery,
           dependent: :destroy,
           inverse_of: :gallery

  has_many :videos,
           dependent: :destroy

  accepts_nested_attributes_for :videos, allow_destroy: true

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader

  before_save :update_slugs
  before_create :set_last_updated_at

  after_save :send_on_sale_notification, if: :saved_change_to_on_sale?
  after_save :broadcast_update
  after_create :send_new_model_notification

  def self.production_status_filters
    Model.all.map(&:production_status).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'productionStatus',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.classification_filters
    Model.all.map(&:classification).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'classification',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.focus_filters
    Model.all.map(&:focus).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'focus',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.size_filters
    Model.all.map(&:size).reject(&:blank?).compact.uniq.map do |item|
      Filter.new(
        category: 'size',
        name: item.humanize,
        value: item
      )
    end
  end

  def self.visible
    where(hidden: false)
  end

  %i[height beam length mass cargo min_crew max_crew scm_speed afterburner_speed].each do |method_name|
    define_method "display_#{method_name}" do
      display_value = try("addition_#{method_name}")
      if display_value.present? && !display_value.zero?
        display_value
      else
        try(method_name)
      end
    end
  end

  def in_hangar(user)
    return if user.blank?
    user.models.exists?(id)
  end

  def on_sale_with_price?
    on_sale? && !price.zero?
  end

  def random_image
    images.enabled.order('RANDOM()').first
  end

  private def broadcast_update
    ActionCable.server.broadcast('models', to_builder.target!)
  end

  private def send_new_model_notification
    ModelMailer.notify_admin(self).deliver_later
    return unless on_sale?
    ActionCable.server.broadcast('on_sale', to_builder.target!)
  end

  private def send_on_sale_notification
    return unless on_sale?
    VehiclesWorker.perform_async(id)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end

  private def set_last_updated_at
    return if last_updated_at.present?
    self.last_updated_at = Time.zone.now
  end

  def to_builder
    Jbuilder.new do |model|
      model.name name
      model.slug slug
    end
  end
end
