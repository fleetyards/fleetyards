# frozen_string_literal: true

module ScData
  # The game keeps a salvage ship's figures on its salvage controller: the
  # crates its filler stations pack, how far and how fast it fractures and
  # grinds a hull. Neither the filler station nor the arm carries them, so this
  # reads each ship's loadout for the controller beside a station or an arm and
  # hands its figures to that part, keyed on the part's own item.
  #
  # The intake on the arm is one item every salvage ship shares, so the hull
  # work goes on the arm, which is each ship's own.
  class SalvageParts
    SIDES = %w[left right front rear].freeze

    STRUCTURAL = %w[fracture disintegration field_alignment field_supporters_required].freeze

    def initialize(models, items_by_key:, items_by_ref:)
      @models = models
      @items_by_key = items_by_key
      @items_by_ref = items_by_ref
    end

    # { item key => {"salvage" => the figures} }, merged into the part's type data.
    def facts
      # In key order, so a part two ships share takes the same ship's figures
      # whichever order the files are read in.
      @facts ||= @models.sort_by { |model| model["key"].to_s }.each_with_object({}) do |model, facts|
        entries = flatten(model["loadout"] || [])
        controllers = entries.select { |entry| salvage_controller?(entry[:item]) }
        next if controllers.empty?

        entries.each do |entry|
          key = entry[:item]&.dig("key")&.downcase
          next if key.blank? || facts.key?(key)

          case entry[:item]["type"]
          when "SalvageFillerStation"
            crates = beside(entry, controllers.select { |controller| controller[:item].dig("type_data", "crates") }) { |data| data.dig("crates", "max_size").to_i }
            facts[key] = {"salvage" => {"crates" => crates[:item]["type_data"]["crates"]}} if crates
          when "ToolArm"
            next unless salvage_arm?(entry)

            structural = beside(entry, controllers.select { |controller| structural?(controller[:item]) }) { |data| data.dig("disintegration", "max_radius").to_f }
            facts[key] = {"salvage" => structural[:item]["type_data"].slice(*STRUCTURAL)} if structural
          end
        end
      end
    end

    # Every entry of a loadout, nested ones included, each holding its own.
    private def flatten(loadout)
      loadout.flat_map do |entry|
        children = flatten(entry["loadout"].presence || entry["default_loadout"] || [])
        node = {name: entry["name"].to_s.downcase, item: item_for(entry), children:}
        [node, *children]
      end
    end

    private def item_for(entry)
      @items_by_key[entry["key"].to_s.downcase] || @items_by_ref[entry["ref"]]
    end

    private def salvage_controller?(item)
      item&.dig("type_data", "salvage_controller").present?
    end

    private def structural?(item)
      item.dig("type_data", "disintegration").present? || item.dig("type_data", "fracture").present?
    end

    # An arm that does salvage, rather than the Prospector's mining arm or a
    # refuel boom: it carries a salvage head or the disintegration intake.
    private def salvage_arm?(entry)
      entry[:children].any? { |child| %w[SalvageHead SalvageFieldEmitter].include?(child[:item]&.dig("type")) }
    end

    # The controller on the same side as the part where the ship has several --
    # the Moth's left cab packs for its left station -- else the one whose
    # figure is largest.
    private def beside(entry, controllers, &size)
      return if controllers.empty?

      side = side_of(entry[:name])
      same_side = controllers.select { |controller| side && side_of(controller[:name]) == side }

      (same_side.presence || controllers).max_by { |controller| size.call(controller[:item]["type_data"]) }
    end

    private def side_of(name)
      SIDES.find { |side| name.split("_").include?(side) }
    end
  end
end
