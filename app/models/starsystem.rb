# frozen_string_literal: true

class Starsystem < ApplicationRecord
  has_many :planets,
           dependent: :nullify

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
