# frozen_string_literal: true

class Ship < ApplicationRecord
  paginates_per 30

  belongs_to :manufacturer, required: false
  belongs_to :ship_role, required: false

  has_one :addition,
          class_name: 'VehicleAddition',
          dependent: :destroy

  delegate :net_cargo, to: :addition, allow_nil: true
  delegate :height, :length, :cargo, :crew, :mass, :beam, to: :addition, allow_nil: true, prefix: true

  accepts_nested_attributes_for :addition, allow_destroy: true

  has_many :hardpoints,
           dependent: :destroy,
           autosave: true
  has_many :components,
           through: :hardpoints
  has_many :propulsion_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: 'propulsion' }) },
           class_name: 'Hardpoint'
  has_many :ordnance_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: 'ordnance' }) },
           class_name: 'Hardpoint'
  has_many :modular_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: 'modular' }) },
           class_name: 'Hardpoint'
  has_many :avionics_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: 'avionics' }) },
           class_name: 'Hardpoint'

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
  after_create :send_new_ship_notification

  def self.enabled
    where(enabled: true)
  end

  def self.production_status_filters
    I18n.t('labels.ship.production_status').map do |status|
      Filter.new(
        category: 'productionStatus',
        name: status[1],
        value: status[0]
      )
    end
  end

  def self.on_sale_filters
    %w[true false].map do |item|
      Filter.new(
        category: 'onSale',
        name: I18n.t("filter.ship.on_sale.items.#{item}"),
        value: item
      )
    end
  end

  def self.classification_filters
    Ship.all.map(&:classification).uniq.compact.map do |item|
      Filter.new(
        category: 'classification',
        name: I18n.t("filter.ship.classification.items.#{item}"),
        value: item
      )
    end
  end

  %i[height beam length mass cargo crew].each do |method_name|
    define_method "display_#{method_name}" do
      display_value = try("addition_#{method_name}")
      if display_value.present? && !display_value.zero?
        display_value
      else
        try(method_name)
      end
    end
  end

  def ship_role_name
    if ship_role.present?
      ship_role.name
    else
      I18n.t('labels.ship.roles.unknown')
    end
  end

  def in_hangar(user)
    return if user.blank?
    user.ships.exists?(id)
  end

  def random_image
    images.enabled.order('RANDOM()').first
  end

  private def broadcast_update
    ActionCable.server.broadcast('updates_ships', to_builder.target!)
  end

  private def send_new_ship_notification
    ShipMailer.notify_admin(self).deliver_later
  end

  private def send_on_sale_notification
    return unless on_sale?

    UserShipsWorker.perform_async(id)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end

  def to_builder
    Jbuilder.new do |ship|
      ship.id id
      ship.name name
      ship.slug slug
      ship.description description
      ship.length display_length.to_f
      ship.beam display_beam.to_f
      ship.height display_height.to_f
      ship.mass display_mass.to_f
      ship.cargo display_cargo
      ship.net_cargo net_cargo
      ship.crew display_crew
      ship.store_image store_image.url
      ship.store_url "#{Rails.application.secrets[:rsi_hostname]}#{store_url}"
      ship.price price
      ship.on_sale on_sale
      ship.production_status production_status
      ship.production_note production_note
      ship.powerplant_size powerplant_size
      ship.shield_size shield_size
      ship.classification classification
      ship.focus focus
      ship.rsi_id rsi_id
      ship.updated_at updated_at
      ship.created_at created_at
    end
  end
end
