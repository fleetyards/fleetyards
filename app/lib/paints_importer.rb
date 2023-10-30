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
      "2950 Invictus Constellation Dark Green" => "Dark Green",
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
      "Star Runner Silver Spark" => "Silver Spark",
      "Star Runner Equinox" => "Equinox",
      "Star Runner Blackguard" => "Blackguard",
      "MOLE Dolivine" => "Dolivine",
      "ROC Dolivine" => "Dolivine",
      "Prospector Dolivine" => "Dolivine",
      "MOLE Aphorite" => "Aphorite",
      "ROC Aphorite" => "Aphorite",
      "Prospector Aphorite" => "Aphorite",
      "MOLE Hadanite" => "Hadanite",
      "ROC Hadanite" => "Hadanite",
      "Prospector Hadanite" => "Hadanite",
      "Nomad Deck the Hull" => "Deck the Hull",
      "Nomad IceBreak" => "Ice Break",
      "Avenger Deck the Hull" => "Deck the Hull",
      "Avenger IceBreak" => "Ice Break",
      "Avenger Splinter" => "Splinter",
      "Avenger Olive Green" => "Olive Green",
      "Anvil Arrow UEE Unity" => "Foundation Festival",
      "Arrow Metallic Grey" => "Metallic Grey",
      "Arrow Twilight" => "Twilight",
      "Arrow Tan and Green" => "Tan and Green",
      "Arrow Light Green and Grey" => "Light Green and Grey",
      "Scrubland" => "Scrubland Camo",
      "Scorpius Blight Green" => "Blight Green",
      "Scorpius Sunburn White Orange" => "Sunburn White Orange",
      "Scorpius Stormcloud Grey" => "Stormcloud Grey",
      "Drake Cutlass Ghoulish Green" => "Ghoulish Green",
      "2950 Invictus Valkyrie Light Grey" => "Light Grey",
      "2950 Invictus Valkyrie Sage" => "Sage",
      "Valkyrie Splinter" => "Splinter",
      "2950 Invictus Freelancer Storm Surge" => "Storm Surge",
      "Starfarer Storm Surge" => "Storm Surge",
      "2950 Invictus Starfarer Light Grey" => "Light Grey",
      "2950 Invictus Starfarer Black" => "Black",
      "Hercules Starlifter Sylvan" => "Sylvan",
      "Hercules Starlifter Argent" => "Argent",
      "Hercules Starlifter Dryad" => "Dryad",
      "Hercules Starlifter BIS 2951" => "Best in Show 2951",
      "Aurora SXSW 2015" => "SXSW 2015",
      "2950 Invictus Aurora Blue and Gold" => "Invictus Blue and Gold",
      "2950 Invictus Aurora Light and Dark Grey" => "Light and Dark Grey",
      "2950 Invictus Auora Green and Gold" => "Green and Gold",
      "AEGIS Vulcan Hazard Yellow" => "Hazard Yellow",
      "AEGIS Vulcan CTR" => "CTR",
      "Crusader Ares Radiance" => "Radiance",
      "Crusader Ares Ember" => "Ember",
      "Freelancer - Black" => "Black"
    }

    return paint_map[name] if paint_map[name].present?

    name
  end

  private def models_mapping(name)
    aurora = ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"]
    avenger = ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"]
    connie = [
      "Constellation Andromeda", "Constellation Aquila", "Constellation Phoenix",
      "Constellation Taurus"
    ]
    cyclone = %w[Cyclone Cyclone-TR Cyclone-RN Cyclone-RC Cyclone-AA]
    vanguard = ["Vanguard Warden", "Vanguard Sentinel", "Vanguard Hoplite", "Vanguard Harbinger"]
    freelancer = ["Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS"]
    tali = ["Retaliator Bomber", "Retaliator"]
    hercules = ["C2 Hercules", "M2 Hercules", "A2 Hercules"]
    gladius = ["Gladius", "Gladius Valiant", "Pirate Gladius"]
    series_100 = %w[100i 125a 135c]
    series_600 = ["600i Touring", "600i Explorer", "600i Executive-Edition"]
    cutlass = ["Cutlass Black", "Cutlass Blue", "Cutlass Red", "Cutlass Steel"]
    fury = ["Fury", "Fury MX", "Fury LX"]
    scorpius = ["Scorpius", "Scorpius Antares"]
    hornet = [
      "F7C-S Hornet Ghost", "F7C-R Hornet Tracker", "F7C-M Super Hornet Heartseeker",
      "F7C-M Super Hornet", "F7C Hornet Wildfire", "F7C Hornet"
    ]
    mercury = ["Mercury Star Runner"]
    roc = %w[ROC ROC-DS]
    prospector = ["Prospector"]
    dragonfly = ["Dragonfly Yellowjacket", "Dragonfly Black"]
    ares = ["Ares Ion", "Ares Inferno"]
    starfarer = ["Starfarer", "Starfarer Gemini"]

    models_map = {
      "Constellation" => connie,
      "2950 Invictus Constellation Blue and Gold" => connie,
      "2950 Invictus Constellation Dark Green" => connie,
      "2950 Invictus Retaliator Midnight Blue and Gold" => tali,
      "Retaliator Twilight" => tali,
      "Retaliator Grey" => tali,
      "Fury Variants" => fury,
      "Fury" => fury,
      "Origin 100 series" => series_100,
      "100 Series Deck the Hull" => series_100,
      "100 Series IceBreak" => series_100,
      "100 Series" => series_100,
      "Origin 100 Series" => series_100,
      "600i" => series_600,
      "600i BIS 2951" => series_600,
      "MPUV BIS 2951" => ["MPUV Personnel", "MPUV Cargo"],
      "Origin X1 Scarlet" => ["X1 Base", "X1 Velocity", "X1 Force"],
      "Mercury Star Runner BIS 2951" => mercury,
      "Star Runner" => mercury,
      "Star Runner Silver Spark" => mercury,
      "Star Runner Equinox" => mercury,
      "Star Runner Blackguard" => mercury,
      "Freelancer Series" => freelancer,
      "Freelancer" => freelancer,
      "Freelancer - Black" => freelancer,
      "2950 Invictus Freelancer Storm Surge" => freelancer,
      "Anvil Hornet" => hornet,
      "MOLE Dolivine" => ["MOLE"],
      "MOLE Aphorite" => ["MOLE"],
      "MOLE Hadanite" => ["MOLE"],
      "ROC Dolivine" => roc,
      "ROC Aphorite" => roc,
      "ROC Hadanite" => roc,
      "Prospector Aphorite" => prospector,
      "Prospector Dolivine" => prospector,
      "Prospector Hadanite" => prospector,
      "Hercules Starlifter" => hercules,
      "Crusader Hercules" => hercules,
      "Hercules Starlifter BIS 2951" => hercules,
      "Hercules Starlifter Sylvan" => hercules,
      "Hercules Starlifter Argent" => hercules,
      "Hercules Starlifter Dryad" => hercules,
      "Drake Cutlass" => cutlass,
      "Cutlass" => cutlass,
      "Drake Cutlass Ghoulish Green" => cutlass,
      "Spirit" => ["A1 Spirit", "C1 Spirit", "E1 Spirit"],
      "Zeus" => ["Zeus Mk II MR", "Zeus Mk II CL", "Zeus Mk II ES"],
      "Gladius Series" => gladius,
      "Gladius" => gladius,
      "Aegis Gladius" => gladius,
      "Dragonfly" => dragonfly,
      "Drake Dragonfly" => dragonfly,
      "Nomad Deck the Hull" => ["Nomad"],
      "Nomad IceBreak" => ["Nomad"],
      "Avenger" => avenger,
      "Avenger Deck the Hull" => avenger,
      "Avenger IceBreak" => avenger,
      "Avenger Splinter" => avenger,
      "Avenger Olive Green" => avenger,
      "Avenger Series" => avenger,
      "Ares Star Fighter" => ares,
      "Ares" => ares,
      "Crusader Ares" => ares,
      "Crusader Ares Radiance" => ares,
      "Crusader Ares Ember" => ares,
      "Anvil Arrow UEE Unity" => ["Arrow"],
      "Arrow Metallic Grey" => ["Arrow"],
      "Arrow Twilight" => ["Arrow"],
      "Arrow Tan and Green" => ["Arrow"],
      "Arrow Light Green and Grey" => ["Arrow"],
      "RSI Scorpius" => scorpius,
      "Scorpius Blight Green" => scorpius,
      "Scorpius Sunburn White Orange" => scorpius,
      "Scorpius Stormcloud Grey" => scorpius,
      "Khartu-al" => ["Khartu-Al"],
      "Tumbril Cyclone" => cyclone,
      "Tumrbil Cyclone" => cyclone,
      "F8C" => ["F8C Lightning", "F8C Lightning Executive Edition"],
      "Aegis Vanguard" => vanguard,
      "Vanguard Series" => vanguard,
      "Vanguard" => vanguard,
      "Mustang" => ["Mustang Omega", "Mustang Gamma", "Mustang Delta", "Mustang Beta", "Mustang Alpha"],
      "2950 Invictus Valkyrie Light Grey" => ["Valkyrie"],
      "2950 Invictus Valkyrie Sage" => ["Valkyrie"],
      "Valkyrie Splinter" => ["Valkyrie"],
      "Starfarer Storm Surge" => starfarer,
      "2950 Invictus Starfarer Light Grey" => starfarer,
      "2950 Invictus Starfarer Black" => starfarer,
      "MISC Reliant" => ["Reliant Kore", "Reliant Mako", "Reliant Sen", "Reliant Tana"],
      "Aurora" => aurora,
      "Aurora SXSW 2015" => aurora,
      "Operation Pitchfork" => aurora,
      "Dread Pirate" => aurora,
      "UEE Distinguished Service" => aurora,
      "2950 Invictus Aurora Blue and Gold" => aurora,
      "2950 Invictus Aurora Light and Dark Grey" => aurora,
      "2950 Invictus Auora Green and Gold" => aurora,
      "Pisces" => ["C8 Pisces", "C8X Pisces Expedition", "C8R Pisces"],
      "Anvil Hawk" => ["Hawk"],
      "Tumbril Nova" => ["Nova"],
      "AEGIS Vulcan Hazard Yellow" => ["Vulcan"],
      "AEGIS Vulcan CTR" => ["Vulcan"]
    }

    return models_map[name.strip] if models_map[name.strip].present?

    name
  end

  private def cleanup_name(text)
    text.gsub(/paint|Paint|livery|Livery|skin|Skin/, "").strip
  end
end
