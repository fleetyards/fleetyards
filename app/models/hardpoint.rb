class Hardpoint < ActiveRecord::Base
  class ComponentCategoryValidator < ActiveModel::Validator
    def validate hardpoint
      if hardpoint.component.present? && hardpoint.component.category_id != hardpoint.category_id
        hardpoint.errors[:component_id] << I18n.t(:"activerecord.errors.models.hardpoint.attributes.component_id.invalid_category")
      end
    end
  end

  translates :name

  belongs_to :ship, touch: true
  belongs_to :component
  belongs_to :category,
    class_name: "ComponentCategory"

  validates_presence_of :ship_id, :category_id

  validates_with ComponentCategoryValidator
end
