class Manufacturer < ActiveRecord::Base
  translates :description

  include SlugHelper

  mount_uploader :logo, LogoUploader

  has_many :ships

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
  end
end
