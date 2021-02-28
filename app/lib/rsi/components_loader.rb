# frozen_string_literal: true

require 'rsi/base_loader'

module Rsi
  class ComponentsLoader < ::Rsi::BaseLoader
    def run(component_data, hardpoint = nil)
      return if component_data[:name].blank? || component_data[:manufacturer].blank? || component_data[:manufacturer] == 'TBD'

      component = create_or_update(component_data)

      hardpoint.update!(component_id: component.id) if hardpoint.present?

      component
    end

    private def create_or_update(component_data)
      component = Component.find_or_create_by!(
        name: component_data[:name],
        size: component_data[:component_size]
      )

      item_type = component_data[:type]
      item_type = 'weapons' if item_type == 'turrets'

      manufacturer = Manufacturer.find_or_create_by!(name: component_data[:manufacturer].strip)

      component.update(
        component_class: component_data[:component_class],
        item_type: item_type,
        manufacturer_id: manufacturer.id
      )

      component
    end
  end
end
