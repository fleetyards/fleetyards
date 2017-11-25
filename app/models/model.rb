# frozen_string_literal: true

class Model < ApplicationRecord
  belongs_to :manufacturer, required: false

  has_one :addition,
          class_name: 'ModelAddition',
          dependent: :destroy

  delegate :net_cargo, to: :addition, allow_nil: true
  delegate :height, :length, :cargo, :max_crew, :min_crew,
           :scm_speed, :afterburner_speed, :mass, :beam, to: :addition, allow_nil: true, prefix: true

  accepts_nested_attributes_for :addition, allow_destroy: true

  has_many :hardpoints,
           dependent: :destroy,
           autosave: true
  has_many :components,
           through: :hardpoints

  has_many :images,
           as: :gallery,
           dependent: :destroy

  has_many :videos,
           dependent: :destroy

  accepts_nested_attributes_for :videos, allow_destroy: true

  mount_uploader :store_image, ImageUploader

  before_save :update_slugs

  after_save :send_on_sale_notification, if: :saved_change_to_on_sale?
  after_save :broadcast_update
  after_create :send_new_model_notification

  def self.production_status_filters
    I18n.t('labels.model.production_status').map do |status|
      Filter.new(
        category: 'productionStatus',
        name: I18n.t("labels.model.production_status.#{status[0]}"),
        value: status[0]
      )
    end
  end

  def self.classification_filters
    Model.all.map(&:classification).uniq.compact.map do |item|
      Filter.new(
        category: 'classification',
        name: I18n.t("filter.model.classification.items.#{item}"),
        value: item
      )
    end
  end

  def self.focus_filters
    Model.all.map(&:focus).compact.uniq.select do |item|
      item.strip.present?
    end.map do |item|
      Filter.new(
        category: 'focus',
        name: item,
        value: item
      )
    end
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

    return unless on_sale_with_price?

    ActionCable.server.broadcast('on_sale', to_builder.target!)
  end

  private def send_on_sale_notification
    return unless on_sale_with_price?

    VehiclesWorker.perform_async(id)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end

  def to_builder
    Jbuilder.new do |model|
      model.name name
      model.slug slug
    end
  end
end
