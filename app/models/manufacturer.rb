# frozen_string_literal: true

# == Schema Information
#
# Table name: manufacturers
#
#  id          :uuid             not null, primary key
#  code        :string
#  description :text
#  known_for   :string(255)
#  logo        :string(255)
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  rsi_id      :integer
#
class Manufacturer < ApplicationRecord
  include ActionView::Helpers::OutputSafetyHelper

  paginates_per 30

  mount_uploader :logo, LogoUploader

  has_many :models,
           dependent: :nullify
  has_many :components,
           dependent: :nullify

  before_save :update_slugs

  ransack_alias :name, :name_or_slug

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

  def name_clean
    # rubocop:disable Rails/OutputSafety
    name&.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
