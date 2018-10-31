# frozen_string_literal: true

class Equipment < ApplicationRecord
  include SlugHelper

  belongs_to :manufacturer, required: false

  validates :name, presence: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  enum equipment_type: %i[armor weapon tool clothing medical]
  ransacker :equipment_type, formatter: proc { |v| Equipment.equipment_types[v] } do |parent|
    parent.table[:equipment_type]
  end

  def self.ordered_by_name
    order(name: :asc)
  end

  def self.type_filters
    Equipment.equipment_types.map do |(item, _index)|
      Filter.new(
        category: 'equipment_type',
        name: Equipment.human_enum_name(:equipment_type, item),
        value: item
      )
    end
  end

  def equipment_type_label
    Equipment.human_enum_name(:equipment_type, equipment_type)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
