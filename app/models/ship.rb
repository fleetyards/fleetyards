# frozen_string_literal: true

class Ship < ApplicationRecord
  paginates_per 30

  default_scope -> { order(name: :asc) }

  belongs_to :manufacturer, required: false
  belongs_to :ship_role, required: false

  has_one :addition,
          class_name: "VehicleAddition",
          dependent: :destroy

  accepts_nested_attributes_for :addition, allow_destroy: true

  has_many :hardpoints,
           dependent: :destroy,
           autosave: true
  has_many :components,
           through: :hardpoints
  has_many :propulsion_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: "propulsion" }) },
           class_name: "Hardpoint"
  has_many :ordnance_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: "ordnance" }) },
           class_name: "Hardpoint"
  has_many :modular_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: "modular" }) },
           class_name: "Hardpoint"
  has_many :avionics_hardpoints,
           -> { includes(:category).where(component_categories: { rsi_name: "avionics" }) },
           class_name: "Hardpoint"

  has_many :images,
           as: :gallery,
           dependent: :destroy

  has_many :videos,
           dependent: :destroy

  accepts_nested_attributes_for :videos, allow_destroy: true

  mount_uploader :store_image, ImageUploader

  before_save :update_slugs

  after_save :notify_users, if: :saved_change_to_on_sale?

  def self.enabled
    where(enabled: true)
  end

  def self.filter(filter_params)
    filter = filter_params.fetch(:filter, [])
    filter_ship_role(select_filter(filter, 'shipRole'))
      .filter_manufacturer(select_filter(filter, 'manufacturer'))
      .filter_production_status(select_filter(filter, 'productionStatus'))
      .filter_on_sale(select_filter(filter, 'onSale'))
      .search(filter_params.fetch(:search, nil))
  end

  def self.filter_ship_role(ship_roles)
    return all if ship_roles.blank?
    includes(:ship_role).where("ship_roles.slug in (?)", ship_roles).references(:ship_role)
  end

  def self.filter_manufacturer(manufacturers)
    return all if manufacturers.blank?
    includes(:manufacturer).where("manufacturers.slug in (?)", manufacturers).references(:manufacturer)
  end

  def self.filter_production_status(production_status)
    return all if production_status.blank?
    where(production_status: production_status)
  end

  def self.filter_on_sale(on_sale)
    return all if on_sale.blank?
    where(on_sale: on_sale)
  end

  def self.select_filter(filter, type)
    filter.map do |item|
      parts = item.split(':')
      next if parts[0] != type
      parts[1]
    end.compact
  end

  def self.search(search_string)
    return all if search_string.blank? || search_string !~ /\w+/
    search_conditions = []
    search_conditions << "lower(ships.name) like :search"
    search_conditions << "lower(ships.description) like :search"
    search_conditions << "lower(ship_roles.name) like :search"
    search_conditions << "lower(manufacturers.name) like :search"
    includes(%i[ship_role manufacturer]).where(
      [
        search_conditions.join(' OR '),
        { search: "%#{search_string.downcase}%" }
      ]
    ).references(%i[ship_role manufacturer])
  end

  %i[height beam length mass cargo crew].each do |method_name|
    define_method method_name do
      if addition.present? && addition.send(method_name).present?
        addition.send(method_name)
      else
        self[method_name]
      end
    end
  end

  def ship_role_name
    if ship_role.present?
      ship_role.name
    else
      I18n.t("labels.ship.roles.unknown")
    end
  end

  def in_hangar(user)
    return if user.blank?
    user.ships.exists?(id)
  end

  def random_image
    images.enabled.order("RANDOM()").first
  end

  private def notify_users
    return unless on_sale?
    UserShipsWorker.perform_async(id)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
