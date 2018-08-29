# frozen_string_literal: true

class Planet < ApplicationRecord
  paginates_per 30

  has_many :stations,
           dependent: :nullify
  has_many :moons,
           class_name: 'Planet',
           dependent: :destroy

  belongs_to :planet, required: false
  belongs_to :starsystem, required: false

  validates :name, presence: true
  validates :planet, presence: true, if: proc { |p| p.starsystem.blank? }
  validates :starsystem, presence: true, if: proc { |p| p.planet.blank? }

  before_save :update_starsystem
  before_save :update_slugs

  private def update_starsystem
    return if starsystem.present? && !will_save_change_to_planet_id?
    self.starsystem = planet.starsystem
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
