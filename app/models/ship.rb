class Ship < ActiveRecord::Base
  translates :description

  belongs_to :manufacturer
  belongs_to :ship_role

  mount_uploader :image, ImageUploader

  before_create :set_name
  before_save :update_slugs

  def self.enabled
    where enabled: true
  end

  private def set_name
    self.name = self.rsi_name
  end

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
  end
end
