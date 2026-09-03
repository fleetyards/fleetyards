# frozen_string_literal: true

# == Schema Information
#
# Table name: manufacturers
#
#  id              :uuid             not null, primary key
#  code            :string
#  code_mapping    :string
#  description     :text
#  icon_overridden :boolean          default(FALSE), not null
#  icon_path       :string
#  known_for       :string(255)
#  logo_overridden :boolean          default(FALSE), not null
#  long_name       :string
#  name            :string(255)
#  sc_ref          :string
#  slug            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  rsi_id          :integer
#
# Indexes
#
#  index_manufacturers_on_slug  (slug) UNIQUE
#
class Manufacturer < ApplicationRecord
  attr_accessor :update_reason, :update_reason_description, :author_id

  # Only an admin action sets `author_id`, so a loader write files nothing. The
  # gate is not tidiness: the UEX sync rewrites all 232 commodities and 1,526 of
  # 4,830 equipment rows a week, and versioning those unconditionally would bury
  # the handful of real edits the way Fleet's touch versions already do.
  has_paper_trail on: %i[update],
    only: %i[
      name long_name code description known_for sc_ref
    ],
    if: ->(record) { record.author_id.present? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
  include ActionView::Helpers::OutputSafetyHelper
  include ActiveStorageVariants
  include AttachmentRansackers

  paginates_per 30

  # Two pictures, from two sources that must not overwrite each other: `logo`
  # is curated -- an admin uploads it, and RSI's own artwork lands there --
  # while `icon` is the art the game export ships, which the sc_data load
  # follows freely. `icon_path` records where in the export that art came from.
  has_one_attached :logo
  ransack_attachment :logo
  has_one_attached :icon

  has_many :models,
    dependent: :nullify
  has_many :components,
    dependent: :nullify
  has_many :equipment,
    dependent: :nullify
  has_many :model_modules,
    dependent: :nullify

  before_save :update_slugs

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = ["name asc", "name desc", "createdAt asc", "createdAt desc"]

  def self.ransackable_attributes(auth_object = nil)
    [
      "code", "code_mapping", "created_at", "description", "id", "id_value", "known_for",
      "logo", "long_name", "name", "rsi_id", "slug", "updated_at"
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
    # The export's art first, the curated logo only where there is none. The
    # export covers roughly five times as many manufacturers, so a list drawn
    # from it is both fuller and visually of one piece -- the curated logo is
    # kept for the ship detail page, where it stands on its own. Not named
    # `icon`: a local by that name would shadow the attachment this reads.
    picture = icon.attached? ? icon : logo
    picture_url = if picture.attached?
      Rails.application.routes.url_helpers.rails_blob_url(picture)
    end

    Filter.new(
      category: "manufacturer",
      label: name_clean,
      icon: picture_url,
      value: slug
    )
  end

  def name_clean
    # rubocop:disable Rails/OutputSafety
    name&.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
