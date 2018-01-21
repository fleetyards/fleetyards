# frozen_string_literal: true

class HangarGroup < ApplicationRecord
  include SlugHelper

  belongs_to :user

  has_many :vehicles, dependent: :nullify

  validates :user_id, :name, :color, presence: true

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
