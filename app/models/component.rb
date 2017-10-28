# frozen_string_literal: true

class Component < ApplicationRecord
  include SlugHelper

  belongs_to :manufacturer, required: false

  validates :name, presence: true

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
