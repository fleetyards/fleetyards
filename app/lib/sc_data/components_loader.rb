# frozen_string_literal: true

module ScData
  class ComponentsLoader < ::ScData::BaseLoader
    attr_accessor :translations_loader

    def initialize
      super

      self.translations_loader = ::ScData::TranslationsLoader.new
    end

    def load(sc_identifier)
      component_data = load_from_export("v2/items/#{sc_identifier.downcase}.json")

      extract_component!(component_data)
    end

    def extract_component!(component_data)
      return if component_data.blank?

      name = component_data['Name']
      name = translations_loader.translate(name) if needs_translation?(name)

      return if name == '<= PLACEHOLDER =>'

      component = Component.find_or_create_by!(
        sc_identifier: component_data['ClassName'],
        name: name
      )

      manufacturer_name = component_data.dig('Manufacturer', 'Name')
      manufacturer = Manufacturer.find_or_create_by!(name: manufacturer_name) if manufacturer_name.present?

      description = component_data['Description']
      description = translations_loader.translate(description) if needs_translation?(description)

      component.update!(
        size: component_data['Size'],
        grade: component_data['Grade'],
        item_class: extract_item_class(description),
        description: description,
        manufacturer: manufacturer || component.manufacturer,
        type_data: extract_type_data(component_data),
        durability: extract_durability(component_data),
        power_connection: extract_power_connection(component_data),
        heat_connection: extract_heat_connection(component_data),
        ammunition: extract_ammunition(component_data)
      )

      component
    end

    private def extract_item_class(description)
      description&.scan(/Class: ((\w|\s)+)\\n/)&.last&.first
    end

    private def extract_type_data(component_data)
      %w[
        Shield MissileRack Missile Weapon PowerPlant Cooler QuantumDrive QuantumFuelTank Thruster
        HydrogenFuelTank HydrogenFuelIntake CargoGrid Radar
      ].filter_map do |type_data_key|
        component_data[type_data_key]
      end.first&.transform_keys(&:underscore)
    end

    private def extract_durability(component_data)
      component_data['Durability']&.transform_keys(&:underscore)
    end

    private def extract_power_connection(component_data)
      component_data['PowerConnection']&.transform_keys(&:underscore)
    end

    private def extract_heat_connection(component_data)
      component_data['HeatConnection']&.transform_keys(&:underscore)
    end

    private def extract_ammunition(component_data)
      component_data['Ammunition']&.transform_keys(&:underscore)
    end

    private def needs_translation?(string)
      return false if string.blank?

      string.start_with?('@')
    end
  end
end
