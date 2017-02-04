# frozen_string_literal: true
class Album < ActiveRecord::Base
  translates :description

  has_many :images, as: :gallery

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug name
  end
end
