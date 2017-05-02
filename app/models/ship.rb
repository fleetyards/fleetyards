# frozen_string_literal: true
class Ship < ActiveRecord::Base
  default_scope -> { order(name: :asc) }

  translates :description

  belongs_to :manufacturer
  belongs_to :ship_role

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

  mount_uploader :store_image, ImageUploader

  before_save :update_slugs

  serialize :propulsion_raw, Array
  serialize :ordnance_raw, Array
  serialize :modular_raw, Array
  serialize :avionics_raw, Array

  def self.enabled
    where(enabled: true)
  end

  def self.filter(filter_params)
    filter_ship_role(filter_params.fetch(:ship_role, nil))
      .filter_manufacturer(filter_params.fetch(:manufacturer, nil))
      .filter_production_status(filter_params.fetch(:production_status, nil))
      .filter_on_sale(filter_params.fetch(:on_sale, nil))
      .search(filter_params.fetch(:search, nil))
  end

  def self.filter_ship_role(ship_role)
    return all if ship_role.blank? || !(ship_role =~ /\w+/)
    includes(:ship_role).where("ship_roles.slug = ?", ship_role).references(:ship_role)
  end

  def self.filter_manufacturer(manufacturer)
    return all if manufacturer.blank? || !(manufacturer =~ /\w+/)
    includes(:manufacturer).where("manufacturers.slug = ?", manufacturer).references(:manufacturer)
  end

  def self.filter_production_status(production_status)
    return all if production_status.blank? || !(production_status =~ /\w+/)
    where(production_status: production_status)
  end

  def self.filter_on_sale(on_sale)
    return all if on_sale.blank? || !(on_sale =~ /^(true|false)$/)
    where(on_sale: on_sale)
  end

  def self.search(search_string)
    return all if search_string.blank? || !(search_string =~ /\w+/)
    search_conditions = []
    search_conditions << "lower(ships.name) like :search"
    search_conditions << "lower(ships.description) like :search"
    search_conditions << "lower(ship_roles.name) like :search"
    includes(:ship_role).where(
      [
        search_conditions.join(' OR '),
        { search: "%#{search_string.downcase}%" }
      ]
    ).references(:ship_role)
  end

  def ship_role_name
    if ship_role.present?
      ship_role.name
    else
      I18n.t("labels.ship.roles.unknown")
    end
  end

  def random_image
    images.enabled.order("RANDOM()").first
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
