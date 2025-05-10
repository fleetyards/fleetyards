class HangarImporter
  attr_accessor :import

  MODEL_FIND_QUERY = [
    "lower(name) = :name",
    "lower(rsi_name) = :name",
    "slug = :slug",
    "rsi_slug = :slug",
    "lower(name) = :normalized_name",
    "lower(rsi_name) = :normalized_name",
    "slug = :normalized_name",
    "rsi_slug = :normalized_name"
  ].freeze

  def initialize(import)
    @import = import
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def run
    @import.start!

    missing_models = []
    imported_models = []

    (@import.import_data || []).each do |item|
      name = item[:name]
      name = legacy_mapping[item[:name]] if legacy_mapping[item[:name]].present?
      name = starship_42_mapping[item[:name]] if starship_42_mapping[item[:name]].present?
      name = hangar_xplor_mapping[item[:name]] if hangar_xplor_mapping[item[:name]].present?

      normalized_name = normalize(name)
      slug = item[:slug].downcase if item[:slug].present?
      slug = item[:paint_slug].downcase if item[:paint_slug].present?

      query = [
        MODEL_FIND_QUERY.join(" OR "),
        {
          name: name.downcase,
          slug:,
          normalized_name:,
          search: "%#{normalized_name}%"
        }
      ]

      params = {
        notify: false,
        user_id: @import.user_id,
        name: item[:ship_name] || item[:custom_name],
        serial: item[:ship_serial],
        flagship: item[:flagship] || false,
        wanted: item[:wanted] || !item[:purchased] || false,
        bought_via: item[:bought_via] || :pledge_store,
        public: item[:public] || false,
        name_visible: item[:name_visible] || false,
        sale_notify: item[:sale_notify] || false,
        hangar_group_ids: HangarGroup.where(user_id: @import.user_id, name: item[:groups]).pluck(:id),
        model_module_ids: ModelModule.where(name: (item[:modules] || []) + (legacy_module_mapping[item["name"]] || [])).pluck(:id),
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
    Vehicle.where(user_id: @import.user_id).update_all(notify: true)
    # rubocop:enable Rails/SkipsModelValidations

    output = {
      missing: missing_models.sort,
      imported: imported_models.sort,
      success: missing_models.size < @import.import_data.size
    }

    @import.update!(output: output)
    @import.finish!

    output
  rescue => e
    @import.fail!
    @import.update!(info: e.message)

    raise e
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def legacy_mapping
    {
      "Ursa Rover" => "Ursa",
      "Ursa Rover Fortuna" => "Ursa Fortuna",
      "Retaliator Bomber" => "Retaliator",
      "F7A Hornet" => "F7A Hornet Mk I",
      "F7C Hornet" => "F7C Hornet Mk I",
      "F7C Hornet Wildfire" => "F7C Hornet Wildfire Mk I",
      "F7C-M Super Hornet" => "F7C-M Super Hornet Mk I",
      "F7C-M Super Hornet Heartseeker" => "F7C-M Super Hornet Heartseeker Mk I",
      "F7C-R Hornet Tracker" => "F7C-R Hornet Tracker Mk I",
      "F7C-S Hornet Ghost" => "F7C-S Hornet Ghost Mk I",
      "F8C" => "F8C Lightning",
      "F8C Lightning Executive-Edition" => "F8C Lightning Executive Edition"
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def legacy_module_mapping
    {
      "Retaliator Bomber" => ["Front Torpedo Bay", "Rear Torpedo Bay"]
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def starship_42_mapping
    {
      "x1" => "X1",
      "315p explorer" => "315p",
      "325a fighter" => "325a",
      "350r racer" => "350r",
      "600i exploration module" => "600i Explorer",
      "600i touring module" => "600i Touring",
      "caterpillar 2949 best in show" => "Caterpillar",
      "cutlass 2949 best in show" => "Cutlass Black",
      "f7a military hornet" => "F7a Hornet Mk I",
      "f7c hornet" => "F7C Hornet Mk I",
      "f7c hornet wildfire" => "F7C Hornet Wildfire Mk I",
      "f7c-r hornet tracker" => "F7C-R Hornet Tracker Mk I",
      "f7c-s hornet ghost" => "F7C-S Hornet Ghost Mk I",
      "f7c-m super hornet" => "F7C-M Super Hornet Mk I",
      "f7c-m super hornet heartseeker" => "F7C-M Super Hornet Mk I",
      "f8c lightning civilian" => "F8C lightning",
      "hammerhead 2949 best in show" => "Hammerhead",
      "hercules starlifter a2" => "A2 Hercules",
      "hercules starlifter c2" => "C2 Hercules",
      "hercules starlifter m2" => "M2 Hercules",
      "mercury star runner" => "Mercury",
      "mustang omega : amd edition" => "Mustang Omega",
      "nova tank" => "Nova",
      "p-72 archimedes" => "P-72 Archimedes",
      "p-72 archimedes emerald" => "P-72 Archimedes Emerald",
      "pisces - expedition" => "C8X Pisces Expedition",
      "reclaimer 2949 best in show" => "Reclaimer",
      "reliant kore - mini hauler" => "Reliant Kore",
      "reliant mako - news van" => "Reliant Mako",
      "reliant sen - researcher" => "Reliant Sen",
      "reliant tana - skirmisher" => "Reliant Tana",
      "c1 spirit" => "C1 Spirit",
      "e1 spirit" => "E1 Spirit",
      "a1 spirit" => "A1 Spirit",
      "crusader mercury star runner" => "Mercury",
      "genesis starliner" => "Genesis",
      "retaliator base" => "Retaliator",
      "retaliator bomber" => "Retaliator",
      "ursa rover" => "Ursa",
      "ursa rover fortuna" => "Ursa Fortuna"
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def hangar_xplor_mapping
    {
      "X1 Base" => "X1",
      "315p Explorer" => "315p",
      "325a Fighter" => "325a",
      "350r Racer" => "350r",
      "600i" => "600i Explorer",
      "600i Exploration Module" => "600i Explorer",
      "600i Touring Module" => "600i Touring",
      "Mercury Star Runner" => "Mercury",
      "Captured Vanduul Scythe" => "Scythe",
      "Caterpillar 2949 Best in Show" => "Caterpillar",
      "Cutlass 2949 Best In Show" => "Cutlass Black",
      "Dragonfly" => "Dragonfly Black",
      "F8C Lightning Civilian" => "F8C Lightning",
      "Hammerhead 2949 Best in Show" => "Hammerhead",
      "Hammerhead Best In Show Edition" => "Hammerhead",
      "Hercules Starlifter A2" => "A2 Hercules",
      "Hercules Starlifter C2" => "C2 Hercules",
      "Hercules Starlifter M2" => "M2 Hercules",
      "Genesis Starliner" => "Genesis",
      "Caterpillar Best In Show Edition" => "Caterpillar",
      "Cutlass Black Best In Show Edition" => "Cutlass Black",
      "F7C Hornet" => "F7C Hornet Mk I",
      "F7C-M Super Hornet Heartseeker" => "F7C-M Super Hornet Mk I",
      "F7A Hornet" => "F7A Hornet Mk I",
      "F7C Hornet Wildfire" => "F7C Hornet Wildfire Mk I",
      "F7C-M Super Hornet" => "F7C-M Super Hornet Mk I",
      "F7C-R Hornet Tracker" => "F7C-R Hornet Tracker Mk I",
      "F7C-S Hornet Ghost" => "F7C-S Hornet Ghost Mk I",
      "Hornet F7C" => "F7C Hornet Mk I",
      "Hornet F7C-M Heartseeker" => "F7C-M Super Hornet Mk I",
      "Idris-M Frigate" => "Idris-M",
      "Idris-P Frigate" => "Idris-P",
      "Idris-K Frigate" => "Idris-P",
      "Greycat PTV" => "PTV",
      "GRIN ROC DS" => "ROC DS",
      "Greycat Industrial - ROC" => "ROC",
      "Gatac Railen" => "Railen",
      "Carrack Expedition with Pisces Expedition" => "Carrack Expedition",
      "Carrack with Pisces Expedition" => "Carrack",
      "Mustang Omega : AMD Edition" => "Mustang Omega",
      "Nova Tank" => "Nova",
      "Pisces" => "C8 Pisces",
      "Pisces - Expedition" => "C8X Pisces Expedition",
      "Reclaimer 2949 Best in Show" => "Reclaimer",
      "Reclaimer Best In Show Edition" => "Reclaimer",
      "Reliant Kore - Mini Hauler" => "Reliant Kore",
      "Reliant Mako - News Van" => "Reliant Mako",
      "Reliant Sen - Researcher" => "Reliant Sen",
      "Reliant Tana - Skirmisher" => "Reliant Tana",
      "Rover" => "G12a",
      "Retaliator Base" => "Retaliator",
      "Retaliator Bomber" => "Retaliator",
      "Ursa Rover" => "Ursa",
      "Ursa Rover Fortuna" => "Ursa Fortuna",
      "Crusader A1 Spirit" => "A1 Spirit",
      "Crusader C1 Spirit" => "C1 Spirit",
      "Crusader E1 Spirit" => "E1 Spirit"
    }
  end
  # rubocop:enable Metrics/MethodLength

  private def normalize(name)
    transform_to_slug(strip_name(name))
  end

  private def transform_to_slug(name)
    return if name.blank?

    slug = name.parameterize

    slug.presence || name
  end

  private def strip_name(name)
    name.gsub(/(?:AEGIS|Aegis|ARGO|argo|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|crusader|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|Consolidated Outland|consolidated outland|frigate|Aopoa)/, "").strip
  end
end
