class Component < ActiveRecord::Base
  translates :name, :component_type

  belongs_to :category,
    class_name: "ComponentCategory"

  validates_presence_of :name, :component_type, :category_id
end
