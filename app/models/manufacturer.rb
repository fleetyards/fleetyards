# frozen_string_literal: true

class Manufacturer < ApplicationRecord
  include SlugHelper
  include ActionView::Helpers::OutputSafetyHelper

  mount_uploader :logo, LogoUploader

  has_many :models, dependent: :nullify
  has_many :components, dependent: :nullify

  def self.with_name
    where.not(name: nil)
  end

  def self.with_model
    includes(:models).where.not(models: { manufacturer_id: nil })
  end

  def self.with_component
    includes(:components).where.not(components: { manufacturer_id: nil })
  end

  def self.model_filters
    Manufacturer.with_name.with_model.order(name: :asc).all.map(&:to_filter)
  end

  def self.component_filters
    Manufacturer.with_name.with_component.order(name: :asc).all.map(&:to_filter)
  end

  def to_filter
    Filter.new(
      category: 'manufacturer',
      name: name,
      icon: (logo.small.url if logo.present?),
      value: slug
    )
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
