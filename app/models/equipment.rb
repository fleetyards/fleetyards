# frozen_string_literal: true

class Equipment < ApplicationRecord
  include SlugHelper

  validates :name, presence: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  enum equipment_type: %i[armor weapon tool clothing medical]

  def self.ordered_by_name
    order(name: :asc)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
