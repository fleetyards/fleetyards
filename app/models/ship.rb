class Ship < ActiveRecord::Base
  translates :description

  belongs_to :manufacturer
  belongs_to :ship_role
  belongs_to :base_class, class_name: Ship, foreign_key: :base
  has_many :variants, class_name: Ship, foreign_key: :base
  has_many :hardpoints
  has_many :weapons, through: :hardpoints
  has_many :images, as: :gallery
  has_and_belongs_to_many :equipment

  mount_uploader :image, ImageUploader

  accepts_nested_attributes_for :images, allow_destroy: true

  before_create :set_name
  before_save :update_slugs

  def self.enabled
    where enabled: true
  end

  def self.base
    where base: nil
  end

  private def set_name
    self.name = self.rsi_name
  end

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
  end
end
