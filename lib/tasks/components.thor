# frozen_string_literal: true

require "thor"

class Components < Thor
  include Thor::Actions

  desc "merge", "Merge Components by Name"
  def merge
    require "./config/environment"

    Component.find_each do |component|
      duplicated_components = Component.where(name: component.name).where.not(id: component.id).all

      duplicated_components.each do |duplicated_component|
        if component.type_data.blank? && duplicated_component.type_data.present?
          component.update(type_data: duplicated_component.type_data)
        end

        duplicated_component.shop_commodities.find_each do |shop_commodity|
          shop_commodity.update(commodity_item_id: component.id)
        end

        ModelHardpoint.where(component_id: duplicated_component.id).find_each do |model_hardpoint|
          model_hardpoint.update(component_id: component.id)
        end

        duplicated_component.destroy
      end
    end
  end
end
