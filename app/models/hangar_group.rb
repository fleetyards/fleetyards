# frozen_string_literal: true

class HangarGroup < ApplicationRecord
  include SlugHelper

  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :vehicles, through: :task_forces

  validates :user_id, :name, :color, presence: true

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
