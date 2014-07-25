class Manufacturer < ActiveRecord::Base
  include SlugHelper

  mount_uploader :logo, LogoUploader

  has_many :ships

  before_create :set_defaults
  before_save :update_slugs

  def self.known
    where("name != ?", "Unknown")
  end

  private def set_defaults
    self.name = self.rsi_name
    self.slug = SlugHelper::generate_slug self.name
  end

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
    self.rsi_slug = SlugHelper::generate_slug self.rsi_name
  end
end
