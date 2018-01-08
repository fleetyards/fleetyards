# frozen_string_literal: true

class Album < ApplicationRecord
  has_many :images,
           as: :gallery,
           dependent: :nullify,
           inverse_of: :album

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug name
  end
end
