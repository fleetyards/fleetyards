# frozen_string_literal: true

class Faction < ApplicationRecord
  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
