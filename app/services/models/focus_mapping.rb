# frozen_string_literal: true

module Models
  # A source's wording of a ship's focus -- the ship matrix's, the game files'
  # or one an admin typed before there was a list -- in the catalogue's keys.
  #
  # Each part of a combination ("Starter / Light Freight") maps on its own. A
  # size tier says nothing the ship's size does not, so it goes, except on a
  # fighter, where a heavy fighter is small or medium and a light one small.
  #
  # The keys come without their umbrellas: a ship gains those as it is saved,
  # and a crew slot must not.
  class FocusMapping
    Result = Data.define(:foci, :stealth, :unknown)

    TIERS = /\A(?:light|medium|heavy)\s+/

    PARTS = {
      "light fighter" => %w[light_fighter],
      "medium fighter" => %w[medium_fighter],
      "heavy fighter" => %w[heavy_fighter],
      "snub fighter" => %w[snub_fighter],
      "fighter" => %w[fighter],
      "interceptor" => %w[light_fighter],
      "stealth fighter" => %w[fighter],
      "bomber" => %w[bomber],
      "stealth bomber" => %w[bomber],
      "gunship" => %w[gunship],
      "gun ship" => %w[gunship],
      "modular gunship" => %w[gunship modular],
      "patrol" => %w[gunship],
      "interdiction" => %w[interdiction],
      "interdictor" => %w[interdiction],
      "dropship" => %w[dropship],
      "boarding" => %w[dropship],
      "military transport" => %w[dropship],
      "minelayer" => %w[minelayer],
      "corvette" => %w[corvette],
      "frigate" => %w[frigate],
      "destroyer" => %w[destroyer],
      "battlecruiser" => %w[battlecruiser],
      "tank" => %w[tank],
      "anti-vehicle" => %w[tank],
      "anti-air" => %w[anti_air],
      "anti-aircraft" => %w[anti_air],
      "combat" => %w[assault],
      "assault" => %w[assault],
      "military" => %w[assault],
      "combat support" => %w[assault],
      "freight" => %w[freight],
      "freighter" => %w[freight],
      "cargo" => %w[freight],
      "cargo loader" => %w[freight],
      "hauler" => %w[freight],
      "passenger" => %w[passenger],
      "transport" => %w[passenger],
      "transporter" => %w[passenger],
      "touring" => %w[touring],
      "luxury" => %w[touring],
      "luxury touring" => %w[touring],
      "luxury transport" => %w[touring],
      "explorer" => %w[expedition],
      "carrier" => %w[carrier],
      "snub carrier" => %w[carrier],
      "merchant" => %w[merchant],
      "mining" => %w[mining],
      "prospecting" => %w[mining],
      "refinery" => %w[refining],
      "refining" => %w[refining],
      "salvage" => %w[salvage],
      "construction" => %w[construction],
      "science" => %w[science],
      "data" => %w[data],
      "reporting" => %w[data],
      "medical" => %w[medical],
      "ambulance" => %w[medical],
      "refuel" => %w[refuel],
      "refueling" => %w[refuel],
      "refueler" => %w[refuel],
      "repair" => %w[repair],
      "recovery" => %w[recovery],
      "expedition" => %w[expedition],
      "exploration" => %w[expedition],
      "recon" => %w[pathfinder],
      "reconnaissance" => %w[pathfinder],
      "intelligence" => %w[pathfinder],
      "pathfinder" => %w[pathfinder],
      "racing" => %w[racing],
      "starter" => %w[starter],
      "generalist" => %w[generalist],
      "modular" => %w[modular],
      "stealth" => []
    }.freeze

    # A part that says something about the ship, just nothing a key does: the
    # ship matrix's "Multi-Role" means only that the other parts follow.
    SILENT = ["multi-role"].freeze

    def self.call(raw)
      new.call(raw)
    end

    def call(raw)
      parts = raw.to_s.split("/").map { |part| part.squish.downcase }.compact_blank

      foci = []
      unknown = []

      parts.each do |part|
        next if SILENT.include?(part)

        keys = PARTS[part] || (PARTS[part.sub(TIERS, "")] unless part.end_with?("fighter"))

        if keys
          foci.concat(keys)
        else
          unknown << part
        end
      end

      Result.new(
        foci: ::Model.ordered_foci(foci),
        stealth: parts.any? { |part| part.start_with?("stealth") },
        unknown:
      )
    end
  end
end
