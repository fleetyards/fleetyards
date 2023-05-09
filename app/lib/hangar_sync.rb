# frozen_string_literal: true

class HangarSync < HangarImporter
  attr_accessor :ships, :components

  def initialize(data)
    @ships = data.select { |item| item[:type] == "ship" }
    @components = data.select { |item| item[:type] == "component" }
  end

  def run(user_id)
    new_vehicles, updated_vehicles, missing_vehicles, missing_models = sync_vehicles(user_id)
    # sync_components(user_id)

    {
      new_vehicles:,
      updated_vehicles:,
      missing_vehicles:,
      missing_models:
    }
  end

  def sync_vehicles(user_id)
    vehicle_ids = []
    new_vehicles = []
    updated_vehicles = []
    missing_vehicles = []
    missing_models = []
    vehicle_scope = Vehicle.where(user_id: user_id, loaner: false, hidden: false).order(created_at: :asc)

    @ships.each do |item|
      query = generate_query(item)
      params = default_params(user_id, item)

      model = Model.where(query).first
      if model.present?
        vehicle_with_ref = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model.id,
          rsi_pledge_id: item[:id]
        )

        if vehicle_with_ref.present?
          vehicle_ids << vehicle_with_ref.id

          if vehicle_with_ref.rsi_pledge_synced_at.nil?
            vehicle_with_ref.update(rsi_pledge_synced_at: Time.current)
            updated_vehicles << vehicle_with_ref.id
          end

          next
        end

        vehicle = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model.id
        )

        if vehicle.present?
          vehicle.update(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)
          vehicle_ids << vehicle.id
          updated_vehicles << vehicle.id
          next
        end

        vehicle = vehicle_scope.create(params.merge(model_id: model.id))
        vehicle_ids << vehicle.id
        new_vehicles << vehicle.id
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
          vehicle_ids << vehicle_with_ref.id

          if vehicle_with_ref.rsi_pledge_synced_at.nil?
            vehicle_with_ref.update(rsi_pledge_synced_at: Time.current)
            updated_vehicles << vehicle_with_ref.id
          end

          next
        end

        vehicle = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model_paint.model_id,
          model_paint_id: model_paint.id
        )

        if vehicle.present?
          vehicle.update(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)
          vehicle_ids << vehicle.id
          updated_vehicles << vehicle.id
          next
        end

        vehicle = vehicle_scope.create(params.merge(model_id: model_paint.model_id, model_paint_id: model_paint.id))
        vehicle_ids << vehicle.id
        new_vehicles << vehicle.id
        next
      end

      missing_models << item[:name]
    end

    vehicle_scope.where.not(id: vehicle_ids).find_each do |vehicle|
      initial_updated_at = vehicle.updated_at
      vehicle.update(rsi_pledge_id: nil, rsi_pledge_synced_at: nil, wanted: true)

      if initial_updated_at != vehicle.updated_at
        missing_vehicles << vehicle.id
      end
    end

    [new_vehicles, updated_vehicles, missing_vehicles, missing_models]
  end

  private def generate_query(item)
    name = item[:name]
    name = rsi_hangar_mapping[item[:name]] if rsi_hangar_mapping[item[:name]].present?
    normalized_name = normalize(name)
    slug = item[:slug].downcase if item[:slug].present?
    slug = item[:paint_slug].downcase if item[:paint_slug].present?

    [
      MODEL_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug:,
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
  private def rsi_hangar_mapping
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
      "Caterpillar 2949 Best in Show" => "caterpillar best in show edition",
      "Cutlass 2949 Best In Show" => "cutlass black best in show edition",
      "Dragonfly" => "Dragonfly Black",
      "F8C Lightning Civilian" => "F8C Lightning",
      "Hammerhead 2949 Best in Show" => "hammerhead best in show edition",
      "Hercules Starlifter A2" => "A2 Hercules",
      "Hercules Starlifter C2" => "C2 Hercules",
      "Hercules Starlifter M2" => "M2 Hercules",
      "Genesis Starliner" => "Genesis",
      "Hornet F7C" => "F7C Hornet",
      "Hornet F7C-M Heartseeker" => "F7C-M Super Hornet Heartseeker",
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
      "Reclaimer 2949 Best in Show" => "reclaimer best in show edition",
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
  end
  # rubocop:enable Metrics/MethodLength
end
