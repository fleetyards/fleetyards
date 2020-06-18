# frozen_string_literal: true

class HangarImporter
  attr_accessor :data

  def initialize(data)
    @data = data.map do |item|
      item.transform_keys(&:underscore)
          .transform_keys(&:to_sym)
    end.filter do |item|
      item[:type].blank? || item[:type] == 'ship'
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def run(user_id)
    missing_models = []
    imported_models = []

    @data.each do |item|
      name = item[:name]
      name = starship_42_mapping[item[:name]] if starship_42_mapping[item[:name]].present?
      name = hangar_xplor_mapping[item[:name]] if hangar_xplor_mapping[item[:name]].present?
      normalized_name = normalize(name)
      slug = item[:slug].downcase if item[:slug].present?

      query = [
        [
          'lower(name) = :name',
          'lower(rsi_name) = :name',
          'slug = :slug',
          'rsi_slug = :slug',
          'lower(name) = :normalized_name',
          'lower(rsi_name) = :normalized_name',
          'slug = :normalized_name',
          'rsi_slug = :normalized_name'
        ].join(' OR '),
        {
          name: name.downcase,
          slug: slug,
          normalized_name: normalized_name,
          search: "%#{normalized_name}%"
        }
      ]

      params = {
        notify: false,
        user_id: user_id,
        name: item[:custom_name],
        flagship: item[:flagship] || false,
        purchased: item[:purchased] || false,
        public: item[:public] || false,
        name_visible: item[:name_visible] || false,
        sale_notify: item[:sale_notify] || false,
        hangar_group_ids: HangarGroup.where(user_id: user_id, name: item[:groups]).pluck(:id),
        model_module_ids: ModelModule.where(name: item[:modules]).pluck(:id),
        model_upgrade_ids: ModelUpgrade.where(name: item[:upgrades]).pluck(:id)
      }

      model = Model.where(query).first
      if model.present?
        Vehicle.create(params.merge(model_id: model.id))
        imported_models << model.name
        next
      end

      model_paint = ModelPaint.where(query).first
      if model_paint.present?
        Vehicle.create(params.merge(model_id: model_paint.model_id, model_paint_id: model_paint.id))
        imported_models << model_paint.name
        next
      end

      missing_models << item[:name]
    end

    # rubocop:disable Rails/SkipsModelValidations
    Vehicle.where(user_id: user_id).update_all(notify: true)
    # rubocop:enable Rails/SkipsModelValidations

    {
      missing: missing_models.sort,
      imported: imported_models.sort,
      success: missing_models.size < @data.size,
    }
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  private def starship_42_mapping
    {
      'x1' => 'X1 Base',
      '315p explorer' => '315p',
      '325a fighter' => '325a',
      '350r racer' => '350r',
      '600i exploration module' => '600i Explorer',
      '600i touring module' => '600i Touring',
      'caterpillar 2949 best in show' => 'caterpillar best in show edition',
      'cutlass 2949 best in show' => 'cutlass black best in show edition',
      'f7a military hornet' => 'F7a Hornet',
      'f8c lightning civilian' => 'F8C lightning',
      'hammerhead 2949 best in show' => 'hammerhead best in show edition',
      'hercules starlifter a2' => 'A2 Hercules',
      'hercules starlifter c2' => 'C2 Hercules',
      'hercules starlifter m2' => 'M2 Hercules',
      'mustang omega : amd edition' => 'Mustang Omega',
      'nova tank' => 'Nova',
      'p-72 archimedes' => 'P-72 Archimedes',
      'p-72 archimedes emerald' => 'P-72 Archimedes Emerald',
      'pisces - expedition' => 'C8X Pisces Expedition',
      'reclaimer 2949 best in show' => 'reclaimer best in show edition',
      'reliant kore - mini hauler' => 'Reliant Kore',
      'reliant mako - news van' => 'Reliant Mako',
      'reliant sen - researcher' => 'Reliant Sen',
      'reliant tana - skirmisher' => 'Reliant Tana'
    }
  end

  private def hangar_xplor_mapping
    {
      '315p Explorer' => '315p',
      '325a Fighter' => '325a',
      '350r Racer' => '350r',
      '600i Exploration Module' => '600i Explorer',
      '600i Touring Module' => '600i Touring',
      'Captured Vanduul Scythe' => 'Scythe',
      'Caterpillar 2949 Best in Show' => 'caterpillar best in show edition',
      'Cutlass 2949 Best In Show' => 'cutlass black best in show edition',
      'F8C Lightning Civilian ' => 'F8C lightning',
      'Hammerhead 2949 Best in Show' => 'hammerhead best in show edition',
      'Hercules Starlifter A2' => 'A2 Hercules',
      'Hercules Starlifter C2' => 'C2 Hercules',
      'Hercules Starlifter M2' => 'M2 Hercules',
      'Hornet F7C' => 'F7C Hornet',
      'Hornet F7C-M Heartseeker' => 'F7C-M Super Hornet Heartseeker',
      'Idris-M Frigate' => 'Idris-M',
      'Idris-P Frigate' => 'Idris-P',
      'Idris-K Frigate' => 'Idris-P',
      'Carrack Expedition with Pisces Expedition' => 'Carrack Expedition',
      'Carrack with Pisces Expedition' => 'Carrack',
      'Mustang Omega : AMD Edition' => 'Mustang Omega',
      'Nova Tank' => 'Nova',
      'Pisces' => 'C8 Pisces',
      'Pisces - Expedition' => 'C8X Pisces Expedition',
      'Reclaimer 2949 Best in Show' => 'reclaimer best in show edition',
      'Reliant Kore - Mini Hauler' => 'Reliant Kore',
      'Reliant Mako - News Van' => 'Reliant Mako',
      'Reliant Sen - Researcher' => 'Reliant Sen',
      'Reliant Tana - Skirmisher' => 'Reliant Tana',
      'Rover' => 'G12a Rover',
      'X1' => 'X1 Base'
    }
  end

  private def normalize(name)
    transform_to_slug(strip_name(name))
  end

  private def transform_to_slug(name)
    return if name.blank?

    slug = name.gsub(/ö/, 'oe')
    slug = slug.gsub(/ü/, 'ue')
    slug = slug.gsub(/ä/, 'ae')
    slug = slug.gsub(/ß/, 'ss')
    slug = slug.gsub(/Ä/, 'Ae')
    slug = slug.gsub(/Ö/, 'Oe')
    slug = slug.gsub(/Ü/, 'Ue')
    slug = slug.gsub(/[éèê]/, 'e')
    slug = slug.gsub(/[àáâ]/, 'a')
    slug = slug.gsub(/[óòô]/, 'o')
    slug = slug.gsub(/[íìî]/, 'i')
    slug = slug.gsub(/[ùúû]/, 'u')
    slug.parameterize
  end

  private def strip_name(name)
    name.gsub(/(?:AEGIS|Aegis|ARGO|argo|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|crusader|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|Consolidated Outland|consolidated outland|frigate|Aopoa)/, '').strip
  end
end
