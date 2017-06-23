# frozen_string_literal: true

class Hardpoint < ApplicationRecord
  class ComponentCategoryValidator < ActiveModel::Validator
    def validate(hardpoint)
      return unless hardpoint.component.present? && hardpoint.component.category_id != hardpoint.category_id
      hardpoint.errors[:component_id] << I18n.t(:"activerecord.errors.models.hardpoint.attributes.component_id.invalid_category")
    end
  end

  belongs_to :ship, touch: true
  belongs_to :component
  belongs_to :category,
             class_name: "ComponentCategory"

  validates :ship_id, :category_id, presence: true

  validates_with ComponentCategoryValidator

  def self.with_name
    where.not(name: nil)
  end
end
