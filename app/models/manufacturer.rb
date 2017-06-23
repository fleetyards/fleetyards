# frozen_string_literal: true

class Manufacturer < ApplicationRecord
  default_scope -> { order(name: :asc) }
  include SlugHelper

  mount_uploader :logo, LogoUploader

  has_many :ships

  def self.enabled
    where(enabled: true)
  end

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
