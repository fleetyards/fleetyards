# frozen_string_literal: true

class Component < ApplicationRecord
  include SlugHelper

  belongs_to :manufacturer, required: false

  validates :name, presence: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  def self.ordered_by_name
    order(name: :asc)
  end

  def self.class_filters
    Component.all.map(&:component_class).uniq.compact.map do |item|
      Filter.new(
        category: 'class',
        name: I18n.t("filter.component.class.items.#{item.downcase}"),
        value: item
      )
    end
  end

  def component_class_label
    I18n.t("filter.component.class.items.#{component_class.downcase}")
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
