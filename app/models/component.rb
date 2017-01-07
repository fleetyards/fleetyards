class Component < ActiveRecord::Base
  default_scope ->{ order(name: :asc) }
  translates :name, :component_type

  belongs_to :category,
    class_name: "ComponentCategory"

  validates_presence_of :name, :component_type, :category_id

  def self.enabled
    where(enabled: true)
  end
end
