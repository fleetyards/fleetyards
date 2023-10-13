require "json"

class PaintsImporter
  def run
    paints = []

    Imports::HangarSync.find_each do |import|
      paints << extract_paints(import)
    end

    results = paints.flatten.uniq.compact.map do |paint|
      import_paint(paint)
    end.flatten

    {
      new: {
        count: results.count { |paint| paint[:new] && !paint[:error] },
        items: results.select { |paint| paint[:new] && !paint[:error] }
      },
      new_with_error: {
        count: results.count { |paint| paint[:new] && paint[:error] },
        items: results.select { |paint| paint[:new] && paint[:error] }
      },
      existing: {
        count: results.count { |paint| paint[:paint_id].present? && !paint[:new] },
        items: results.select { |paint| paint[:paint_id].present? && !paint[:new] }
      },
      model_not_found: {
        count: results.count { |paint| paint[:model_id].blank? },
        items: results.select { |paint| paint[:model_id].blank? }
      }
    }
  end

  def list_paints(filter = nil)
    Imports::HangarSync.find_each do |import|
      paints << extract_paints(import)
    end

    paints.flatten.uniq.compact.select do |paint|
      return true if filter.blank?

      paint[:model_name].include?(filter) || paint[:name].include?(filter)
    end
  end

  private def extract_paints(import)
    return if import.input.blank? || import.input.starts_with?("{")

    imported_data = JSON.parse(import.input)

    imported_data.filter_map do |item|
      next if item["type"] != "skin" || item["image"].blank?

      name_parts = item["name"].split(" - ")
      {
        name: cleanup_name(name_parts.last),
        model_name: cleanup_name(name_parts.first),
        image: item["image"]
      }
    end
  rescue JSON::ParserError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Paints Data could not be parsed: #{import.input}"
    nil
  end

  private def import_paint(paint)
    model_names = models_mapping(paint[:model_name])

    models = Model.where(name: model_names).all

    paint_name = paint_mapping(paint[:name])

    if models.blank?
      return {
        new: false,
        paint_id: nil,
        model_id: nil,
        model_name: model_names,
        name: paint_name,
        error: false
      }
    end

    models.map do |model|
      existing_paint = ModelPaint.find_by(model_id: model.id, name: paint_name)

      if existing_paint.present?
        return {
          new: false,
          paint_id: existing_paint.id,
          model_id: model.id,
          model_name: model.name,
          name: paint_name,
          error: false
        }
      end

      ModelPaint.create!(
        model_id: model.id,
        name: paint_name,
        remote_store_image_url: paint[:image],
        hidden: true,
        active: true
      )

      {
        new: true,
        paint_id: 1,
        model_id: model.id,
        model_name: model.name,
        name: paint_name,
        error: false
      }
    rescue => e
      Sentry.capture_exception(e)
      Rails.logger.error "Paint could not be imported: #{paint[:name]}"
      {
        new: true,
        paint_id: 1,
        model_id: model.id,
        model_name: model.name,
        name: paint_name,
        error: true
      }
    end
  end

  private def paint_mapping(name)
    paint_map = {
      "2950 Invictus Constellation Blue and Gold" => "2950 Invictus Blue and Gold",
      "2950 Invictus Retaliator Midnight Blue and Gold" => "2950 Invictus Blue and Gold",
      "Retaliator Twilight" => "Twilight",
      "Retaliator Grey" => "Grey",
      "Red Alert" => "Best in Show 2952 (Red Alert)",
      "Foundation Fest" => "Foundation Festival",
      "Best in Show" => "Best in Show 2950",
      "100 Series Deck the Hull" => "Deck the Hull",
      "100 Series IceBreak" => "Ice Break",
      "100 Series Sand Wave" => "Sand Wave",
      "600i BIS 2951" => "Best in Show 2951",
      "MPUV BIS 2951" => "Best in Show 2951",
      "Origin X1 Scarlet" => "Scarlet",
      "Mercury Star Runner BIS 2951" => "Best in Show 2951",
      "MOLE Dolivine" => "Dolivine",
      "ROC Dolivine" => "Dolivine",
      "Prospector Dolivine" => "Dolivine",
      "Nomad Deck the Hull" => "Deck the Hull",
      "Nomad IceBreak" => "Ice Break",
      "Avenger Deck the Hull" => "Deck the Hull",
      "Avenger IceBreak" => "Ice Break",
      "Anvil Arrow UEE Unity" => "Foundation Festival",
      "Scrubland" => "Scrubland Camo"
    }

    return paint_map[name] if paint_map[name].present?

    name
  end

  private def models_mapping(name)
    models_map = {
      "2950 Invictus Constellation Blue and Gold" => ["Constellation Andromeda", "Constellation Aquila", "Constellation Phoenix", "Constellation Taurus"],
      "2950 Invictus Retaliator Midnight Blue and Gold" => ["Retaliator Bomber", "Retaliator"],
      "Retaliator Twilight" => ["Retaliator Bomber", "Retaliator"],
      "Retaliator Grey" => ["Retaliator Bomber", "Retaliator"],
      "Fury Variants" => ["Fury", "Fury MX", "Fury LX"],
      "Fury" => ["Fury", "Fury MX", "Fury LX"],
      "Origin 100 series" => %w[100i 125a 135c],
      "100 Series Deck the Hull" => %w[100i 125a 135c],
      "100 Series IceBreak" => %w[100i 125a 135c],
      "600i" => ["600i Touring", "600i Explorer", "600i Executive-Edition"],
      "600i BIS 2951" => ["600i Touring", "600i Explorer", "600i Executive-Edition"],
      "MPUV BIS 2951" => ["MPUV Personnel", "MPUV Cargo"],
      "Origin X1 Scarlet" => ["X1 Base", "X1 Velocity", "X1 Force"],
      "Mercury Star Runner BIS 2951" => ["Mercury Star Runner"],
      "Star Runner" => ["Mercury Star Runner"],
      "Avenger" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Freelancer Series" => ["Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS"],
      "MOLE Dolivine" => ["MOLE"],
      "ROC Dolivine" => %w[ROC ROC-DS],
      "Prospector Dolivine" => ["Prospector"],
      "Cutlass" => ["Cutlass Black", "Cutlass Blue", "Cutlass Red", "Cutlass Steel"],
      "Spirit" => ["A1 Spirit", "C1 Spirit", "E1 Spirit"],
      "Gladius Series" => ["Gladius", "Gladius Valiant", "Pirate Gladius"],
      "Gladius" => ["Gladius", "Gladius Valiant", "Pirate Gladius"],
      "Dragonfly" => ["Dragonfly Yellowjacket", "Dragonfly Black"],
      "Drake Dragonfly" => ["Dragonfly Yellowjacket", "Dragonfly Black"],
      "Nomad Deck the Hull" => ["Nomad"],
      "Nomad IceBreak" => ["Nomad"],
      "Avenger Deck the Hull" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Avenger IceBreak" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Ares Star Fighter" => ["Ares Ion", "Ares Inferno"],
      "Anvil Arrow UEE Unity" => ["Arrow"],
      "RSI Scorpius" => ["Scorpius"]
    }

    return models_map[name] if models_map[name].present?

    name
  end

  private def cleanup_name(text)
    text.gsub(/paint|Paint|livery|Livery|skin|Skin/, "").strip
  end
end
