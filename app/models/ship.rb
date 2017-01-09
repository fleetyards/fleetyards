class Ship < ActiveRecord::Base
  default_scope ->{ order(name: :asc) }

  translates :description

  belongs_to :manufacturer
  belongs_to :ship_role

  has_many :hardpoints,
    dependent: :destroy,
    autosave: true
  has_many :components,
    through: :hardpoints
  has_many :propulsion_hardpoints,
    ->{ includes(:category).where(component_categories: {rsi_name: "propulsion"}) },
    class_name: "Hardpoint"
  has_many :ordnance_hardpoints,
    ->{ includes(:category).where(component_categories: {rsi_name: "ordnance"}) },
    class_name: "Hardpoint"
  has_many :modular_hardpoints,
    ->{ includes(:category).where(component_categories: {rsi_name: "modular"}) },
    class_name: "Hardpoint"
  has_many :avionics_hardpoints,
    ->{ includes(:category).where(component_categories: {rsi_name: "avionics"}) },
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

  private def update_slugs
    self.slug = SlugHelper::generate_slug(self.name)
  end
end
