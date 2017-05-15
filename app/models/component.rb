# frozen_string_literal: true

class Component < ActiveRecord::Base
  default_scope -> { order(name: :asc) }
  translates :name, :component_type

  belongs_to :category,
             class_name: "ComponentCategory"

  validates :name, :component_type, :category_id, presence: true

  def self.enabled
    where(enabled: true)
  end
end
