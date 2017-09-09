# frozen_string_literal: true

class Manufacturer < ApplicationRecord
  default_scope -> { order(name: :asc) }
  include SlugHelper
  include ActionView::Helpers::OutputSafetyHelper

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

  def self.ship_filters
    Manufacturer.enabled.with_name.with_ship.order(name: :asc).all.map do |manufacturer|
      Filter.new(
        category: 'manufacturer',
        name: manufacturer.name,
        icon: manufacturer.logo.small.url,
        value: manufacturer.slug
      )
    end
  end

  before_save :update_slugs

  def name_clean
    # rubocop:disable Rails/OutputSafety
    name.html_safe
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
