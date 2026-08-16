module ScData
  module Parser
    class EquipmentParser < ScData::Parser::BaseParser
      # Personal gear only. The weapons folder also holds turrets, hardpoint
      # mounted guns and cosmetic modifiers, which belong to ships and are
      # already covered by the items parser.
      SOURCE_PATHS = %w[
        entities/scitem/weapons/fps_weapons
        entities/scitem/weapons/melee
        entities/scitem/weapons/weapon_modifier
        entities/scitem/weapons/magazines
        entities/scitem/weapons/throwable
        entities/scitem/weapons/mines
        entities/scitem/characters/human/armor
        entities/scitem/characters/human/clothing
        entities/scitem/characters/human/starwear
      ].freeze

      # AttachDef Type is the game's own split between a weapon and the things
      # that bolt onto one. Magazines sit under WeaponAttachment there, which is
      # why ammunition is not a category of its own.
      EQUIPMENT_TYPES = {
        "WeaponPersonal" => "weapon",
        "WeaponAttachment" => "weapon_attachment",
        "AmmoBox" => "weapon_attachment",
        "Grenade" => "weapon",
        "Gadget" => "tool",
        "Light" => "tool"
      }.freeze

      # The record key reads manufacturer_class_damage_index, so the second
      # segment names the class. Anything not listed keeps the raw segment
      # rather than being forced into a neighbour.
      ITEM_TYPES = {
        "sniper" => "sniper_rifle",
        "glauncher" => "grenade_launcher",
        "optics" => "weapon_scope",
        "ubarrel" => "underbarrel",
        "ltp" => "mining_tool",
        "medgun" => "medical_tool"
      }.freeze

      WEAPON_CLASSES = %w[ballistic energy kinetic].freeze

      # Worn gear names its slot in the AttachDef Type rather than a SubType:
      # Char_Armor_Helmet, Char_Clothing_Feet. The torso carries two clothing
      # layers, which the slot enum already separates into shirt and jacket.
      CHAR_TYPES = {
        "Char_Armor_Helmet" => ["armor", "helmet"],
        "Char_Armor_Torso" => ["armor", "torso"],
        "Char_Armor_Arms" => ["armor", "arms"],
        "Char_Armor_Legs" => ["armor", "legs"],
        "Char_Armor_Backpack" => ["armor", "backpack"],
        "Char_Armor_Undersuit" => ["undersuit", "undersuit"],
        "Char_Clothing_Torso_0" => ["clothing", "shirt"],
        "Char_Clothing_Torso_1" => ["clothing", "jacket"],
        "Char_Clothing_Legs" => ["clothing", "pants"],
        "Char_Clothing_Feet" => ["clothing", "footwear"],
        "Char_Clothing_Hat" => ["clothing", "hat"],
        "Char_Clothing_Hands" => ["clothing", "gloves"],
        "Char_Clothing_Backpack" => ["clothing", "backpack"]
      }.freeze

      # "All", "Light", "Medium & Heavy" -- the spec block writes the pairs with
      # an ampersand or a comma depending on the field.
      COMPATIBILITY = {
        "all" => "all",
        "light" => "light",
        "heavy" => "heavy",
        "medium&heavy" => "medium_heavy",
        "heavy&medium" => "medium_heavy",
        "light&medium" => "light_medium",
        "medium&light" => "light_medium"
      }.freeze

      # Tints, store and collector editions, and the marketing and template
      # records that never reach a player. They carry their own key, so they
      # load as rows, but a picker listing twelve Pyro RYT Multi-Tools is not
      # useful -- Component solves the same problem the same way.
      VARIANT_SUFFIX = /_(tint|collector|store|mr|sf|prop|template|black|mat|tan)\d*\z/

      # Copies that exist for a game mode, an NPC, or a developer rather than a
      # player: the AI loadout, the tug-of-war and gun-game event weapons, the
      # multi-tool pre-fitted with each attachment, and anything named test or
      # placeholder. Derived from the records that collide on a display name --
      # twelve of the duplicates were Pyro RYT Multi-Tools.
      VARIANT_MARKERS = [
        /_(ai|tow|gungame|contestedzonereward|ea_elim)(_|\z)/,
        /_default_/,
        /placeholder/,
        /test/
      ].freeze

      def all
        save_items(equipment, folder: "equipment")
      end

      def equipment
        mark_skins(load_equipment_data.filter_map { |item| parse_equipment(item) })
      end

      # Records that share a display name and a maker-and-type key prefix are
      # colourways of one item: the seventeen mym_shirt_01_01_NN all read
      # "Davlos Shirt (Charcoal)", and grin_multitool_01_ai copies
      # grin_multitool_01. Only the first by key stays visible.
      #
      # Both tests earn their place. Without the name, a rifle's magazine would
      # be hidden by the rifle it shares a prefix with; without the prefix, the
      # two makers who both ship a "BR-2 Shotgun" would collapse into one.
      private def mark_skins(parsed)
        parsed.group_by { |item| item[:name] }.each_value do |named|
          next if named.one?

          named.group_by { |item| item[:key].split("_").first(2).join("_") }.each_value do |family|
            family.sort_by { |item| item[:key] }.drop(1).each { |item| item[:hidden] = true }
          end
        end

        parsed
      end

      private def parse_equipment(item)
        values = item[:values]
        attach_def = values.dig("Components", "SAttachableComponentParams", "AttachDef")

        return if attach_def.blank?

        name = translate(attach_def.dig("Localization", "Name"))

        return if value_or_nil(name).blank?

        key = item[:key]
        segments = key.split("_")
        described = describe(translate(attach_def.dig("Localization", "Description")))
        worn_type, slot = CHAR_TYPES[attach_def["Type"]]

        {
          key:,
          ref: value_or_nil(values.dig("__ref")),
          name: value_or_nil(name),
          description: described[:description],
          equipment_type: worn_type || EQUIPMENT_TYPES[attach_def["Type"]],
          slot:,
          # The description header is written by hand and says "Assault Rifle"
          # where the record key only says "rifle", so it wins where it exists.
          item_type: described[:item_type] || item_type(segments),
          weapon_class: described[:weapon_class] || WEAPON_CLASSES.find { |klass| segments.include?(klass) },
          rate_of_fire: described[:rate_of_fire],
          range: described[:range],
          storage: described[:storage],
          damage_reduction: described[:damage_reduction],
          temperature_rating: described[:temperature_rating],
          radiation_protection: described[:radiation_protection],
          radiation_scrub_rate: described[:radiation_scrub_rate],
          g_force_tolerance: described[:g_force_tolerance],
          core_compatibility: described[:core_compatibility],
          backpack_compatibility: described[:backpack_compatibility],
          icon: icon(values),
          sub_type: value_or_nil(attach_def["SubType"]),
          size: value_or_nil(attach_def["Size"]),
          grade: value_or_nil(attach_def["Grade"]),
          manufacturer_ref: value_or_nil(attach_def["Manufacturer"]),
          tags: attach_def["Tags"].to_s.split,
          hidden: variant?(key)
        }
      end

      # Most descriptions open with a spec block -- "Item Type: Assault Rifle",
      # "Class: Ballistic", "Rate Of Fire: 550 rpm" -- separated from the prose
      # by a blank line. Component reads the same shape for ship parts.
      private def describe(value)
        text = value_or_nil(value.to_s.gsub('\\n', "\n"))

        return {description: nil} if text.blank?

        # The block runs to the first paragraph that is prose rather than
        # "Key: value" lines. It is several paragraphs deep on a weapon --
        # manufacturer and class, then the numbers, then the attachment slots.
        blocks = text.split("\n\n")
        header = blocks.take_while { |block| spec_block?(block) }

        return {description: text.strip} if header.empty?

        prose = blocks.drop(header.size).join("\n\n")

        fields = header.join("\n").split("\n").filter_map { |line|
          key, value = line.split(":", 2)
          [key.strip.downcase, value.to_s.strip]
        }.to_h

        {
          description: prose.to_s.strip.presence,
          item_type: fields["item type"]&.parameterize(separator: "_"),
          weapon_class: WEAPON_CLASSES.find { |klass| fields["class"].to_s.casecmp?(klass) },
          rate_of_fire: numeric(fields["rate of fire"]),
          range: numeric(fields["effective range"]),
          storage: numeric(fields["magazine size"] || fields["capacity"] || fields["battery size"] || fields["carrying capacity"]),
          damage_reduction: numeric(fields["damage reduction"]),
          # Left as written -- it is a range, "-225 / 75 °C", not a figure.
          temperature_rating: fields["temp. rating"].presence,
          radiation_protection: numeric(fields["radiation protection"]),
          radiation_scrub_rate: numeric(fields["radiation scrub rate"]),
          g_force_tolerance: numeric(fields["g-force tolerance"]),
          core_compatibility: compatibility(fields["core compatibility"]),
          # The same idea under two labels: armour says "Backpacks", the few
          # undersuits that mention it say "Backpack Compatibility".
          backpack_compatibility: compatibility(fields["backpacks"] || fields["backpack compatibility"])
        }
      end

      private def compatibility(value)
        return if value.blank?

        COMPATIBILITY[value.downcase.gsub(/[\s,]*(&|,)[\s,]*/, "&").gsub(/\s+/, "")]
      end

      # A short label before the colon on every line. The length bound keeps a
      # prose sentence that happens to contain a colon out of the spec block.
      private def spec_block?(block)
        lines = block.split("\n").reject(&:blank?)

        lines.any? && lines.all? { |line| line.match?(/\A[^:]{1,30}:/) }
      end

      # Carrying capacity is written "8.0 µSCU" on a suit but "180K µSCU" on a
      # backpack, so the multiplier has to be read rather than the digits alone.
      private def numeric(value)
        return if value.blank?

        # Upper case, and not the first letter of a longer unit: "50 m" is fifty
        # metres, not fifty million, and "147.42 REM/s" is not a multiplier either.
        match = value.match(/(?<number>[\d.]+)\s*(?<scale>[KM](?![A-Za-z]))?/)

        return if match.nil?

        scale = {"K" => 1_000, "M" => 1_000_000}.fetch(match[:scale], 1)

        match[:number].to_d * scale
      end

      # A 64px loadout icon, shared by every variant of a weapon rather than
      # unique to a record -- all seventeen P4-AR records name the same file,
      # and no attachment names one at all. Stored for when the export starts
      # carrying the assets; nothing resolves the path today.
      private def icon(values)
        path = values.dig("StaticEntityClassData", "EntityUIDisplayParams", "displayIcon")

        value_or_nil(path)&.downcase
      end

      private def variant?(key)
        VARIANT_SUFFIX.match?(key) || VARIANT_MARKERS.any? { |marker| marker.match?(key) }
      end

      private def item_type(segments)
        segment = segments[1]

        return if segment.blank?

        ITEM_TYPES.fetch(segment, segment)
      end

      private def load_equipment_data
        SOURCE_PATHS.flat_map do |path|
          Dir.glob("#{import_path}/#{path}/**/*.xml").filter_map do |file|
            data = Hash.from_xml(File.read(file))

            {
              key: File.basename(file, ".xml"),
              values: data.values.first
            }
          end
        end
      end
    end
  end
end
