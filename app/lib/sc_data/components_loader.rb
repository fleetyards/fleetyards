# frozen_string_literal: true

module ScData
  class ComponentsLoader < ::ScData::BaseLoader
    attr_accessor :translations_loader

    def initialize
      super

      self.base_url = "#{base_url}/items"
      self.translations_loader = ::ScData::TranslationsLoader.new
    end

    def extract_from_ref(component_ref)
      sc_identifier = component_ref['entityClassName']

      component_data = load(sc_identifier)

      loadouts = extract_loadouts(component_ref)
      loadout_identifier = loadouts.first['entityClassName'] if loadouts.present?

      component_data.merge({
                             mount: component_ref['itemPortName'],
                             loadouts: loadouts,
                             loadout_identifier: loadout_identifier
                           })
    end

    def load(sc_identifier)
      item_response = fetch_remote("#{sc_identifier.downcase}.json")

      return unless item_response.success?

      item_data = parse_json_response(item_response)

      component_data = item_data.dig('Raw', 'Entity', 'Components')

      {
        component: component_data,
        identifier: sc_identifier,
        base: extract_base_component_data(component_data),
        ports: extract_ports(component_data)
      }
    end

    def create_or_update(sc_identifier)
      item = load(sc_identifier)

      return if item.dig(:base, :name) == '<= PLACEHOLDER =>'

      component = Component.find_or_create_by(name: item.dig(:base, :name))

      manufacturer_name = item.dig(:base, :description).scan(/Manufacturer: ((\w|\s)+)\\n/).last&.first

      if component.present?
        manufacturer = Manufacturer.find_or_create_by(name: manufacturer_name) if manufacturer_name.present?

        component.update(
          size: item.dig(:base, :size),
          grade: item.dig(:base, :grade),
          description: item.dig(:base, :description),
          manufacturer: manufacturer || component.manufacturer
        )
      end

      component
    end

    def extract_loadouts(component_ref)
      component_ref.dig('loadout', 'SItemPortLoadoutManualParams', 'entries') || []
    end

    private def extract_ports(component_data)
      component_data.dig('SCItem', 'ItemPorts', 0, 'Ports') || []
    end

    private def extract_base_component_data(component_data)
      base_data = component_data.dig('SAttachableComponentParams', 'AttachDef')
      localized_data = base_data['Localization']

      {
        size: base_data['Size'],
        grade: base_data['Grade'],
        type: base_data['Type'],
        sub_type: base_data['SubType'],
        category: category(base_data),
        name: translations_loader.translate(localized_data['Name']),
        description: translations_loader.translate(localized_data['Description'])
      }
    end

    private def category(base_data)
      type_to_category(base_data['Type']) || sub_type_to_category(base_data['SubType'])
    end

    private def type_to_category(value)
      mapping = {
        'MainThruster' => :main
      }

      return if mapping[value].blank?

      mapping[value]
    end

    private def sub_type_to_category(value)
      mapping = {
        'MannedTurret' => :manned_turret,
        'BallTurret' => :remote_turret,
        'FixedThruster' => :fixed,
        'JointThruster' => :joint
      }

      return if mapping[value].blank?

      mapping[value]
    end
  end
end
