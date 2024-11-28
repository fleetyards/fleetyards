# frozen_string_literal: true

# == Schema Information
#
# Table name: manufacturers
#
#  id           :uuid             not null, primary key
#  code         :string
#  code_mapping :string
#  description  :text
#  known_for    :string(255)
#  logo         :string(255)
#  long_name    :string
#  name         :string(255)
#  sc_ref       :string
#  slug         :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  rsi_id       :integer
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

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = ["name asc", "name desc", "created_at asc", "created_at desc"]

  def self.ransackable_attributes(auth_object = nil)
    [
      "code", "code_mapping", "created_at", "description", "id", "id_value", "known_for", "logo",
      "long_name", "name", "rsi_id", "slug", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["components", "models"]
  end

  def self.with_name
    where.not(name: nil)
  end

  def self.with_model
    includes(:models).where.not(models: {manufacturer_id: nil})
  end

  def self.with_component
    includes(:components).where.not(components: {manufacturer_id: nil})
  end

  def self.model_filters
    Manufacturer.with_name.with_model.order(name: :asc).all.map(&:to_filter)
  end

  def self.component_filters
    Manufacturer.with_name.with_component.order(name: :asc).all.map(&:to_filter)
  end

  def to_filter
    Filter.new(
      category: "manufacturer",
      label: name_clean,
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
