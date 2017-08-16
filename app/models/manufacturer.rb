# frozen_string_literal: true

class Manufacturer < ApplicationRecord
  default_scope -> { order(name: :asc) }
  include SlugHelper

  mount_uploader :logo, LogoUploader

  has_many :ships

  def self.enabled
    where(enabled: true)
  end

  def self.with_name
    where.not(name: nil)
  end

  def self.with_ship
    includes(:ships).where.not(ships: { manufacturer_id: nil })
  end

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
