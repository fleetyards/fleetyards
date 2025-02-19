class HangarSync < HangarImporter
  attr_accessor :data, :ships, :components, :upgrades

  ITEM_TYPES = %w[ship component upgrade skin].freeze

  COMPONENT_FIND_QUERY = [
    "lower(name) = :name",
    "slug = :slug",
    "lower(name) = :normalized_name",
    "slug = :normalized_name"
  ].freeze

  def initialize(data)
    @data = data.map(&:deep_symbolize_keys)
    @ships = @data.select { |item| item[:type] == "ship" }
    @components = @data.select { |item| item[:type] == "component" }
    @upgrades = @data.select { |item| item[:type] == "upgrade" }
  end

  def run(user_id)
    import = Imports::HangarSync.create!(
      user_id:,
      input: @data.to_json
    )
    import.start!

    imported_vehicles, found_vehicles, moved_vehicles_to_wanted, missing_models = sync_vehicles(user_id)
    imported_components, found_components, missing_components, missing_component_vehicles = sync_components(user_id)
    imported_upgrades, found_upgrades, missing_upgrades, missing_upgrade_vehicles = sync_upgrades(user_id)

    output = {
      imported_vehicles:,
      found_vehicles:,
      moved_vehicles_to_wanted:,
      missing_models:,
      imported_components:,
      found_components:,
      missing_components:,
      missing_component_vehicles:,
      imported_upgrades:,
      found_upgrades:,
      missing_upgrades:,
      missing_upgrade_vehicles:
    }

    import.update!(output: output.to_json)
    import.finish!

    output
  rescue => e
    import&.fail!
    import&.update!(info: e.message)

    raise e
  end

  def sync_vehicles(user_id)
    vehicle_ids = []
    imported_vehicles = []
    found_vehicles = []
    moved_vehicles_to_wanted = []
    missing_models = []
    vehicle_scope = Vehicle.where(user_id: user_id, loaner: false, hidden: false).order(model_paint_id: :desc, created_at: :asc)

    @ships.each do |item|
      query = generate_model_query(item[:name])
      params = default_params(user_id, item)

      model = Model.where(query).first
      if model.present?
        vehicle_with_ref = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model.id,
          rsi_pledge_id: item[:id]
        )

        if vehicle_with_ref.present?
          vehicle_with_ref.update!(
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle_with_ref.name,
            wanted: false
          )

          vehicle_ids << vehicle_with_ref.id
          found_vehicles << vehicle_with_ref.id

          next
        end

        vehicle = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model.id
        )

        if vehicle.present?
          vehicle.update!(
            rsi_pledge_id: item[:id],
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle.name,
            wanted: false
          )

          vehicle_ids << vehicle.id
          found_vehicles << vehicle.id

          next
        end

        vehicle = vehicle_scope.create!(params.merge(model_id: model.id))
        vehicle_ids << vehicle.id
        imported_vehicles << vehicle.id
        next
      end

      model_paint = ModelPaint.where(query).first
      if model_paint.present?
        vehicle_with_ref = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model_paint.model_id,
          model_paint_id: model_paint.id,
          rsi_pledge_id: item[:id]
        )

        if vehicle_with_ref.present?
          vehicle_with_ref.update!(
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle_with_ref.name,
            wanted: false
          )

          vehicle_ids << vehicle_with_ref.id
          found_vehicles << vehicle_with_ref.id

          next
        end

        vehicle = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model_paint.model_id,
          model_paint_id: model_paint.id
        )

        if vehicle.present?
          vehicle.update!(
            rsi_pledge_id: item[:id],
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle.name,
            wanted: false
          )
          vehicle_ids << vehicle.id
          found_vehicles << vehicle.id
          next
        end

        vehicle = vehicle_scope.create!(params.merge(model_id: model_paint.model_id, model_paint_id: model_paint.id))
        vehicle_ids << vehicle.id
        imported_vehicles << vehicle.id
        next
      end

      missing_models << item[:name]
    end

    vehicle_scope.where.not(id: vehicle_ids).find_each do |vehicle|
      initial_updated_at = vehicle.updated_at
      vehicle.update!(rsi_pledge_id: nil, rsi_pledge_synced_at: nil, wanted: true)

      if initial_updated_at != vehicle.updated_at
        moved_vehicles_to_wanted << vehicle.id
      end
    end

    [imported_vehicles, found_vehicles, moved_vehicles_to_wanted, missing_models]
  end

  private def sync_components(user_id)
    vehicle_module_ids = []
    imported_components = []
    found_components = []
    missing_components = []
    missing_component_vehicles = []

    @components.each do |item|
      model_name = item[:name].split(" ").first
      component_name = item[:name].gsub(model_name, "").strip.delete_prefix("-").strip

      model_query = generate_model_query(model_name)
      model = Model.where(model_query).first
      if model.blank?
        missing_components << item[:name]
        next
      end

      component_query = generate_module_query(component_name)
      component = model.modules.where(component_query).first
      if component.blank?
        missing_components << item[:name]
        next
      end

      user = User.find(user_id)

      vehicle_module_with_ref = user.vehicle_modules.where(
        model_module_id: component.id,
        rsi_pledge_id: item[:id]
      ).first
      if vehicle_module_with_ref.present?
        vehicle_module_with_ref.update!(rsi_pledge_synced_at: Time.current)

        vehicle_module_ids << vehicle_module_with_ref.id
        found_components << vehicle_module_with_ref.id

        next
      end

      vehicle_module = user.vehicle_modules.where.not(id: vehicle_module_ids).find_by(
        model_module_id: component.id
      )
      if vehicle_module.present?
        vehicle_module.update!(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)

        vehicle_module_ids << vehicle_module.id
        found_components << vehicle_module.id

        next
      end

      vehicle = Vehicle.where(
        user_id: user_id, loaner: false, hidden: false, model_id: component.model_ids
      ).order(created_at: :asc).first
      if vehicle.blank?
        missing_component_vehicles << item[:name]

        next
      end

      new_vehicle_module = vehicle.vehicle_modules.create!(model_module_id: component.id)

      vehicle_module_ids << new_vehicle_module.id
      imported_components << new_vehicle_module.id
    end

    [imported_components, found_components, missing_components, missing_component_vehicles]
  end

  private def sync_upgrades(user_id)
    vehicle_upgrade_ids = []
    imported_upgrades = []
    found_upgrades = []
    missing_upgrades = []
    missing_upgrade_vehicles = []

    @upgrades.each do |item|
      upgrade_query = generate_upgrade_query(item[:name])
      upgrade = ModelUpgrade.where(upgrade_query).first
      if upgrade.blank?
        missing_upgrades << item[:name]
        next
      end

      user = User.find(user_id)

      vehicle_upgrade_with_ref = user.vehicle_upgrades.where(
        model_upgrade_id: upgrade.id,
        rsi_pledge_id: item[:id]
      ).first
      if vehicle_upgrade_with_ref.present?
        vehicle_upgrade_with_ref.update!(rsi_pledge_synced_at: Time.current)

        vehicle_upgrade_ids << vehicle_upgrade_with_ref.id
        found_upgrades << vehicle_upgrade_with_ref.id

        next
      end

      vehicle_upgrade = user.vehicle_upgrades.where.not(id: vehicle_upgrade_ids).find_by(
        model_upgrade_id: upgrade.id
      )
      if vehicle_upgrade.present?
        vehicle_upgrade.update!(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)

        vehicle_upgrade_ids << vehicle_upgrade.id
        found_upgrades << vehicle_upgrade.id

        next
      end

      vehicle = Vehicle.where(user_id: user_id, loaner: false, hidden: false, model_id: upgrade.model_ids).order(created_at: :asc).first
      if vehicle.blank?
        missing_upgrade_vehicles << item[:name]

        next
      end

      new_vehicle_upgrade = vehicle.vehicle_upgrades.create!(model_upgrade_id: upgrade.id)

      vehicle_upgrade_ids << new_vehicle_upgrade.id
      imported_upgrades << new_vehicle_upgrade.id
    end

    [imported_upgrades, found_upgrades, missing_upgrades, missing_upgrade_vehicles]
  end

  private def generate_model_query(item_name)
    name = rsi_hangar_mapping(item_name)
    normalized_name = normalize(name)

    [
      MODEL_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  private def generate_module_query(item_name)
    name = rsi_hangar_module_mapping(item_name)
    normalized_name = normalize(name)

    [
      COMPONENT_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  private def generate_upgrade_query(item_name)
    name = item_name
    # Add mapping when needed
    # name = rsi_hangar_upgrade_mapping(item_name)
    normalized_name = normalize(name)

    [
      COMPONENT_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  private def default_params(user_id, item)
    {
      notify: false,
      user_id:,
      name: item[:custom_name],
      wanted: false,
      bought_via: :pledge_store,
      public: true,
      name_visible: false,
      sale_notify: false,
      rsi_pledge_id: item[:id],
      rsi_pledge_synced_at: Time.current
    }
  end

  # rubocop:disable Metrics/MethodLength
  private def rsi_hangar_mapping(name)
    name = name.tr("–", "-")

    mapping = {
      "A.T.L.S" => "ATLS",
      "A.T.L.S." => "ATLS",
      "GreyCat Estate Geotack Planetary Beacon" => "Geotack Planetary Beacon",
      "GreyCat Estate Geotack-X Planetary Beacon" => "Geotack-X Planetary Beacon",
      "X1 Base" => "X1",
      "315p Explorer" => "315p",
      "325a Fighter" => "325a",
      "350r Racer" => "350r",
      "Ursa Rover" => "Ursa",
      "Ursa Rover Fortuna" => "Ursa Fortuna",
      "600i" => "600i Explorer",
      "600i Exploration Module" => "600i Explorer",
      "600i Touring Module" => "600i Touring",
      "Mercury Star Runner" => "Mercury",
      "Captured Vanduul Scythe" => "Scythe",
      "Caterpillar 2949 Best in Show" => "Caterpillar Best In Show Edition",
      "Cutlass 2949 Best In Show" => "cutlass black best in show edition",
      "Dragonfly" => "Dragonfly Black",
      "F8C Lightning Civilian" => "F8C Lightning",
      "Hammerhead 2949 Best in Show" => "hammerhead best in show edition",
      "Hercules Starlifter A2" => "A2 Hercules",
      "Hercules Starlifter C2" => "C2 Hercules",
      "Hercules Starlifter M2" => "M2 Hercules",
      "Genesis Starliner" => "Genesis",
      "Hornet F7C Mk I" => "F7C Hornet Mk I",
      "F7A Hornet Mk 1" => "F7A Hornet Mk I",
      "F7C-M Hornet Heartseeker Mk I" => "F7C-M Super Hornet Heartseeker Mk I",
      "Hornet F7C-M Heartseeker Mk I" => "F7C-M Super Hornet Heartseeker Mk I",
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
      "Reclaimer 2949 Best in Show" => "reclaimer best in show edition 2949",
      "Reliant Kore - Mini Hauler" => "Reliant Kore",
      "Reliant Mako - News Van" => "Reliant Mako",
      "Reliant Sen - Researcher" => "Reliant Sen",
      "Reliant Tana - Skirmisher" => "Reliant Tana",
      "Rover" => "G12a Rover",
      "Retaliator Base" => "Retaliator",
      "Crusader A1 Spirit" => "A1 Spirit",
      "Crusader C1 Spirit" => "C1 Spirit",
      "Crusader E1 Spirit" => "E1 Spirit"
    }

    return name if mapping[name.strip].nil?

    mapping[name.strip]
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  private def rsi_hangar_module_mapping(name)
    name = name.tr("–", "-")

    mapping = {
      "RETALIATOR FRONT LIVING MODULE" => "Front Living Module",
      "Retaliator Front Living Module" => "Front Living Module",
      "RETALIATOR REAR LIVING MODULE" => "Rear Living Module",
      "Retaliator Rear Living Module" => "Rear Living Module",
      "RETALIATOR FRONT DROP SHIP MODULE" => "Front Dropship Module",
      "Retaliator Front Drop Ship Module" => "Front Dropship Module",
      "RETALIATOR TORPEDO Module - Bow" => "Front Torpedo Bay",
      "Retaliator Torpedo Module - Bow" => "Front Torpedo Bay",
      "RETALIATOR TORPEDO Module - Stern" => "Rear Torpedo Bay",
      "Retaliator Torpedo Module - Stern" => "Rear Torpedo Bay",
      "RETALIATOR CARGO MODULE - BOW" => "Front Cargo Module",
      "RETALIATOR CARGO MODULE - STERN" => "Rear Cargo Module",
      "Retaliator Cargo Module - Bow" => "Front Cargo Module",
      "Retaliator Cargo Module - Stern" => "Rear Cargo Module",
      "Retaliator Personnel Module - Bow" => "Front Living Module",
      "Retaliator Personnel Module - Stern" => "Rear Living Module",
      "Retaliator Drop Ship Module - Bow" => "Front Dropship Module",
      "FRONT LIVING MODULE" => "Front Living Module",
      "Front Living Module" => "Front Living Module",
      "REAR LIVING MODULE" => "Rear Living Module",
      "Rear Living Module" => "Rear Living Module",
      "FRONT DROP SHIP MODULE" => "Front Dropship Module",
      "Front Drop Ship Module" => "Front Dropship Module",
      "TORPEDO Module - Bow" => "Front Torpedo Bay",
      "Torpedo Module - Bow" => "Front Torpedo Bay",
      "TORPEDO Module - Stern" => "Rear Torpedo Bay",
      "Torpedo Module - Stern" => "Rear Torpedo Bay",
      "Cargo Module - Bow" => "Front Cargo Module",
      "Cargo Module - Stern" => "Rear Cargo Module",
      "CARGO MODULE - BOW" => "Front Cargo Module",
      "CARGO MODULE - STERN" => "Rear Cargo Module",
      "Personnel Module - Bow" => "Front Living Module",
      "Personnel Module - Stern" => "Rear Living Module",
      "Drop Ship Module - Bow" => "Front Dropship Module"
    }

    return name if mapping[name.strip].nil?

    mapping[name.strip]
  end
  # rubocop:enable Metrics/MethodLength

  private def rsi_hangar_upgrade_mapping(name)
    mapping = {
      "Hurston Dynamics Exodus Laser Beam" => "Idris-K"
    }

    return name if mapping[name.strip].nil?

    mapping[name.strip]
  end
end
