# frozen_string_literal: true
class ComponentCategory < ActiveRecord::Base
  translates :name

  has_many :components

  validates :name, presence: true

  before_validation :set_name
  before_save :update_slugs

  private def set_name
    self.name = rsi_name.capitalize
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug name
  end
end
