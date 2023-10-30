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
    models_map = {
      "Constellation" => ["Constellation Andromeda", "Constellation Aquila", "Constellation Phoenix", "Constellation Taurus"],
      "2950 Invictus Constellation Blue and Gold" => ["Constellation Andromeda", "Constellation Aquila", "Constellation Phoenix", "Constellation Taurus"],
      "2950 Invictus Constellation Dark Green" => ["Constellation Andromeda", "Constellation Aquila", "Constellation Phoenix", "Constellation Taurus"],
      "2950 Invictus Retaliator Midnight Blue and Gold" => ["Retaliator Bomber", "Retaliator"],
      "Retaliator Twilight" => ["Retaliator Bomber", "Retaliator"],
      "Retaliator Grey" => ["Retaliator Bomber", "Retaliator"],
      "Fury Variants" => ["Fury", "Fury MX", "Fury LX"],
      "Fury" => ["Fury", "Fury MX", "Fury LX"],
      "Origin 100 series" => %w[100i 125a 135c],
      "100 Series Deck the Hull" => %w[100i 125a 135c],
      "100 Series IceBreak" => %w[100i 125a 135c],
      "100 Series" => %w[100i 125a 135c],
      "Origin 100 Series" => %w[100i 125a 135c],
      "600i" => ["600i Touring", "600i Explorer", "600i Executive-Edition"],
      "600i BIS 2951" => ["600i Touring", "600i Explorer", "600i Executive-Edition"],
      "MPUV BIS 2951" => ["MPUV Personnel", "MPUV Cargo"],
      "Origin X1 Scarlet" => ["X1 Base", "X1 Velocity", "X1 Force"],
      "Mercury Star Runner BIS 2951" => ["Mercury Star Runner"],
      "Star Runner" => ["Mercury Star Runner"],
      "Star Runner Silver Spark" => ["Mercury Star Runner"],
      "Star Runner Equinox" => ["Mercury Star Runner"],
      "Star Runner Blackguard" => ["Mercury Star Runner"],
      "Freelancer Series" => ["Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS"],
      "Freelancer" => ["Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS"],
      "Freelancer - Black" => ["Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS"],
      "2950 Invictus Freelancer Storm Surge" => ["Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS"],
      "Anvil Hornet" => ["F7C-S Hornet Ghost", "F7C-R Hornet Tracker", "F7C-M Super Hornet Heartseeker", "F7C-M Super Hornet", "F7C Hornet Wildfire", "F7C Hornet"],
      "MOLE Dolivine" => ["MOLE"],
      "MOLE Aphorite" => ["MOLE"],
      "MOLE Hadanite" => ["MOLE"],
      "ROC Dolivine" => %w[ROC ROC-DS],
      "ROC Aphorite" => %w[ROC ROC-DS],
      "ROC Hadanite" => %w[ROC ROC-DS],
      "Prospector Aphorite" => ["Prospector"],
      "Prospector Dolivine" => ["Prospector"],
      "Prospector Hadanite" => ["Prospector"],
      "Hercules Starlifter" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
      "Crusader Hercules" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
      "Hercules Starlifter BIS 2951" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
      "Hercules Starlifter Sylvan" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
      "Hercules Starlifter Argent" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
      "Hercules Starlifter Dryad" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
      "Drake Cutlass" => ["Cutlass Black", "Cutlass Blue", "Cutlass Red", "Cutlass Steel"],
      "Cutlass" => ["Cutlass Black", "Cutlass Blue", "Cutlass Red", "Cutlass Steel"],
      "Drake Cutlass Ghoulish Green" => ["Cutlass Black", "Cutlass Blue", "Cutlass Red", "Cutlass Steel"],
      "Spirit" => ["A1 Spirit", "C1 Spirit", "E1 Spirit"],
      "Zeus" => ["Zeus Mk II MR", "Zeus Mk II CL", "Zeus Mk II ES"],
      "Gladius Series" => ["Gladius", "Gladius Valiant", "Pirate Gladius"],
      "Gladius" => ["Gladius", "Gladius Valiant", "Pirate Gladius"],
      "Aegis Gladius" => ["Gladius", "Gladius Valiant", "Pirate Gladius"],
      "Dragonfly" => ["Dragonfly Yellowjacket", "Dragonfly Black"],
      "Drake Dragonfly" => ["Dragonfly Yellowjacket", "Dragonfly Black"],
      "Nomad Deck the Hull" => ["Nomad"],
      "Nomad IceBreak" => ["Nomad"],
      "Avenger" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Avenger Deck the Hull" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Avenger IceBreak" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Avenger Splinter" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Avenger Olive Green" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Avenger Series" => ["Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock"],
      "Ares Star Fighter" => ["Ares Ion", "Ares Inferno"],
      "Ares" => ["Ares Ion", "Ares Inferno"],
      "Crusader Ares" => ["Ares Ion", "Ares Inferno"],
      "Crusader Ares Radiance" => ["Ares Ion", "Ares Inferno"],
      "Crusader Ares Ember" => ["Ares Ion", "Ares Inferno"],
      "Anvil Arrow UEE Unity" => ["Arrow"],
      "Arrow Metallic Grey" => ["Arrow"],
      "Arrow Twilight" => ["Arrow"],
      "Arrow Tan and Green" => ["Arrow"],
      "Arrow Light Green and Grey" => ["Arrow"],
      "RSI Scorpius" => ["Scorpius", "Scorpius Antares"],
      "Scorpius Blight Green" => ["Scorpius", "Scorpius Antares"],
      "Scorpius Sunburn White Orange" => ["Scorpius", "Scorpius Antares"],
      "Scorpius Stormcloud Grey" => ["Scorpius", "Scorpius Antares"],
      "Khartu-al" => ["Khartu-Al"],
      "Tumbril Cyclone" => %w[Cyclone Cyclone-TR Cyclone-RN Cyclone-RC Cyclone-AA],
      "F8C" => ["F8C Lightning", "F8C Lightning Executive Edition"],
      "Aegis Vanguard" => ["Vanguard Warden", "Vanguard Sentinel", "Vanguard Hoplite", "Vanguard Harbinger"],
      "Vanguard Series" => ["Vanguard Warden", "Vanguard Sentinel", "Vanguard Hoplite", "Vanguard Harbinger"],
      "Vanguard" => ["Vanguard Warden", "Vanguard Sentinel", "Vanguard Hoplite", "Vanguard Harbinger"],
      "Mustang" => ["Mustang Omega", "Mustang Gamma", "Mustang Delta", "Mustang Beta", "Mustang Alpha"],
      "2950 Invictus Valkyrie Light Grey" => ["Valkyrie"],
      "2950 Invictus Valkyrie Sage" => ["Valkyrie"],
      "Valkyrie Splinter" => ["Valkyrie"],
      "Starfarer Storm Surge" => ["Starfarer", "Starfarer Gemini"],
      "2950 Invictus Starfarer Light Grey" => ["Starfarer", "Starfarer Gemini"],
      "2950 Invictus Starfarer Black" => ["Starfarer", "Starfarer Gemini"],
      "MISC Reliant" => ["Reliant Kore", "Reliant Mako", "Reliant Sen", "Reliant Tana"],
      "Aurora" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "Aurora SXSW 2015" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "Operation Pitchfork" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "Dread Pirate" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "UEE Distinguished Service" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "2950 Invictus Aurora Blue and Gold" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "2950 Invictus Aurora Light and Dark Grey" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "2950 Invictus Auora Green and Gold" => ["Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR"],
      "Pisces" => ["C8 Pisces", "C8X Pisces Expedition", "C8R Pisces"],
      "Anvil Hawk" => ["Hawk"],
      "Tumbril Nova" => ["Nova"],
      "AEGIS Vulcan Hazard Yellow" => ["Vulcan"],
      "AEGIS Vulcan CTR" => ["Vulcan"]
    }

    return models_map[name] if models_map[name].present?

    name
  end

  private def cleanup_name(text)
    text.gsub(/paint|Paint|livery|Livery|skin|Skin/, "").strip
  end
end
