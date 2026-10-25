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
        entities/scitem/characters/human/head/npc/eyes/accessories
        entities/scitem/consumables
      ].freeze

      # Folders of things a player picks up and carries rather than wears or
      # fires. A folder with a type files everything in it under that type; the
      # carryables mix food, containers, keepsakes and keycards, so each of
      # those records is typed on its own.
      CARRIED_PATHS = {
        "entities/scitem/weapons/devices" => "mining_gadget",
        "entities/scitem/flair" => "flair",
        "entities/scitem/carryables/1h" => nil,
        "entities/scitem/carryables/2h" => nil,
        "entities/scitem/carryables/tractorbeamonly" => nil,
        "entities/scitem/suit" => :suit
      }.freeze

      # The suit folder holds the mobiGlas casings and the thruster packs: worn
      # gear whose AttachDef names neither a slot nor a family. The rest of it --
      # radar, displays, a test armour -- is part of a suit rather than something
      # bought for one.
      SUIT_TYPES = {
        "MobiGlas" => %w[clothing mobiglas_casing],
        "ThrusterPack" => %w[armor thruster_pack]
      }.freeze

      CARRIED_EQUIPMENT_TYPES = %w[mining_gadget flair carryable container sustenance].freeze

      SUIT_ITEM_TYPES = SUIT_TYPES.values.map(&:last).freeze

      # Gear the carried folders hold among props. The game files the flares
      # with the flair and calls them grenades, and the tool cases are "Misc",
      # so each takes its type from here.
      PICKED_RECORDS = [
        [/_(glowstick|flare)_/, "tool", "flare"],
        [/_container_anim_(medgun|(grin_)?multitool)_/, "tool", "tool_case"]
      ].freeze

      # Carried records that never reach a player's inventory: mission props,
      # datapads, the templates the game clones a prop from, and the lootable
      # boxes that are part of a location rather than something to take away.
      CARRIED_NOISE = /missionitem|datapad|template|lootableitem|destroyedinventory|miningbase/

      # Carried AttachDef Types that file a record whatever its key. A crate is
      # hauled cargo, which the commodities parser owns.
      CARRIED_TYPES = {
        "Food" => "sustenance",
        "Drink" => "sustenance",
        "InventoryContainer" => "container",
        "Container" => "container",
        "Cargo" => nil
      }.freeze

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

      # Hand-held gadgets the game files as personal weapons: the multitool,
      # tractor beam, fire extinguisher, rangefinder and Cambio SRT carry the
      # Gadget subtype, and the ParaMed says what it is only in its header or,
      # without one, in its medgun key. A player browsing weapons has no use for
      # them; one browsing tools does.
      TOOL_SUB_TYPES = %w[Gadget].freeze
      TOOL_ITEM_TYPES = %w[medical_device medical_tool].freeze

      # The record key reads manufacturer_class_damage_index, so the second
      # segment names the class. Anything not listed keeps the raw segment
      # rather than being forced into a neighbour.
      ITEM_TYPES = {
        "sniper" => "sniper_rifle",
        "glauncher" => "grenade_launcher",
        "optics" => "weapon_scope",
        "ubarrel" => "underbarrel",
        "ltp" => "mine",
        "medgun" => "medical_tool",
        "gren" => "grenade"
      }.freeze

      # Worn gear's key often puts an outfit line or a faction second --
      # cba_chef_jacket, spv_bioticorp_rep_heels, sc_nvy_bdu_trouser -- so the
      # garment is whichever segment names one, and a key naming none has no
      # item type rather than a theme posing as one.
      GARMENTS = {
        "apron" => "apron",
        "backpack" => "backpack",
        "bandana" => "bandana",
        "boots" => "boots",
        "dress" => "dress",
        "glasses" => "glasses",
        "gloves" => "gloves",
        "goggles" => "goggles",
        "gown" => "dress",
        "hat" => "hat",
        "heels" => "shoes",
        "helmet" => "helmet",
        "jacket" => "jacket",
        "jumpsuit" => "jumpsuit",
        "mask" => "mask",
        "monocle" => "monocle",
        "pants" => "pants",
        "scrubs" => "shirt",
        "shirt" => "shirt",
        "shoes" => "shoes",
        "shorts" => "pants",
        "slippers" => "shoes",
        "suit" => "suit",
        "tanktop" => "shirt",
        "tophat" => "tophat",
        "trenchcoat" => "trenchcoat",
        "trouser" => "pants",
        "vest" => "vest"
      }.freeze

      # Armour without a description header still names its weight in the key,
      # and the headers that do exist read "Heavy Armor" or "Medium Backpack".
      ARMOR_WEIGHTS = {
        "superheavy" => "super_heavy",
        "heavy" => "heavy",
        "medium" => "medium",
        "light" => "light"
      }.freeze

      WEAPON_CLASSES = %w[ballistic energy kinetic].freeze

      # The pair CIG leaves on an unmeasured record: one microSCU in a 0.15m box.
      UNMEASURED_MICRO_SCU = 1.0
      UNMEASURED_SIDE = 0.15

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
        "Char_Clothing_Backpack" => ["clothing", "backpack"],
        "Char_Accessory_Eyes" => ["clothing", "eyewear"]
      }.freeze

      # Consumables split by SubType rather than by Type: the tree writes both
      # FPS_Consumable and RemovableChip, and neither tells a keycard from a
      # hacking chip -- SystemAccess holds both, and the five orbital keycards
      # are filed under Hacking. The families are the two the model has been
      # carrying unused since the weapons landed.
      #
      # item_type here is only the fallback. Sixteen of the nineteen medical
      # records open their description with "Item Type: Medical Consumable",
      # which wins, so the three that say nothing -- OxyPen among them -- take
      # the same words rather than adding near-synonyms to a picker's filter.
      # Every named record under Hacking or SystemAccess reads as a keycard, an
      # access card or a decryption key, bar the drives below.
      CONSUMABLE_TYPES = {
        "Medical" => ["medical", "medical_consumable"],
        "MedPack" => ["medical", "medical_consumable"],
        "OxygenCap" => ["medical", "medical_consumable"],
        "Hacking" => ["hacking_tool", "keycard"],
        "SystemAccess" => ["hacking_tool", "keycard"]
      }.freeze

      # SystemAccess also holds the three ASD drives, which are data storage
      # carried off a delving site rather than something that opens a door.
      # Filed by key because the subtype cannot tell them apart, and left out of
      # the keycard filter so a player looking for one does not read past them.
      DATA_DRIVE_KEY = /_harddrive_/

      CONSUMABLE_ATTACH_TYPES = %w[FPS_Consumable RemovableChip].freeze

      COMMODITY_NAME_PREFIX = ScData::Parser::CommoditiesParser::NAME_PREFIX

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

      # Props and the templates the game clones a record from, which never reach
      # a player. Tints, store and collector editions do: each has a name of its
      # own and several are sold in game shops. A copy under the same name is
      # still hidden, by `mark_skins`.
      VARIANT_SUFFIX = /_(prop|template)\d*\z/

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

      # A base key names at least maker, class and kind -- behr_rifle_ballistic --
      # so a two-segment record cannot claim every key that starts like it.
      MIN_BASE_SEGMENTS = 3

      WORN_EQUIPMENT_TYPES = %w[armor clothing undersuit].freeze

      # A skin's own name, in straight or curly, double or single quotes.
      QUOTED_NAME = /\s*["“”'‘’][^"“”'‘’]+["“”'‘’]\s*/

      def all
        save_items(equipment, folder: "equipment")
      end

      def equipment
        assign_families(mark_skins(load_equipment_data.filter_map { |item| parse_equipment(item) }))
      end

      # Records that share a display name and a maker-and-type key prefix are
      # colourways of one item: the seventeen mym_shirt_01_01_NN all read
      # "Davlos Shirt (Charcoal)", and grin_multitool_01_ai copies
      # grin_multitool_01. Only the first by key stays visible.
      #
      # Both tests earn their place. Without the name, a rifle's magazine would
      # be hidden by the rifle it shares a prefix with; without the prefix, the
      # two makers who both ship a "BR-2 Shotgun" would collapse into one.
      #
      # A carried prop's key names no maker -- the same plushie is filed as
      # plushy_orison_whale_1_a and carryable_1h_cy_toy_plushy_orison_whale_1_a
      # -- so its type stands in for the prefix. The suit gear's keys name the
      # wearer's sex instead, so its item type does.
      private def mark_skins(parsed)
        parsed.group_by { |item| item[:name] }.each_value do |named|
          next if named.one?

          named.group_by { |item| skin_family(item) }.each_value do |family|
            family.sort_by { |item| item[:key] }.drop(1).each { |item| item[:hidden] = true }
          end
        end

        parsed
      end

      # Versions of one item share a `family_key`. A weapon skin's key extends
      # its base item's -- klwe_rifle_energy_01_white02 is the Gallant Rifle in
      # "Boneyard" colours -- and the family is named after the shortest such
      # base. The base has to be the same type of item, or a rifle's magazine
      # would read as a version of the rifle, and the name has to say it is a
      # version: attachment keys extend other products' -- the Quell Suppressor
      # is arma_barrel_supp_s1_02, under the Tacit -- and so do posters,
      # keycards and the LL sights.
      #
      # Worn colourways have no base record: the Defiance Arms in each colour
      # are slaver_armor_heavy_arms_01_01_NN, so they share the key without its
      # last segment instead. An item with no other version has no family.
      private def assign_families(parsed)
        by_key = parsed.index_by { |item| item[:key] }
        bases = parsed.to_h { |item| [item[:key], base_key(item, by_key)] }

        # A version whose name matches only an intermediate record -- a skin of
        # a skin -- still belongs to the root's family.
        root = ->(key) { bases[key] ? root.call(bases[key]) : key }
        roots = bases.filter_map { |key, base| root.call(key) if base }.to_set

        parsed.each do |item|
          item[:family_key] = root.call(item[:key]) if bases[item[:key]] || roots.include?(item[:key])
        end

        assign_worn_families(parsed, by_key)

        parsed
      end

      # One prefix can cover different pieces -- arms and legs, or a test record
      # beside an undersuit -- so the colourways are grouped by kind as well,
      # and a prefix shared by several kinds names each after its slot or type.
      #
      # A colourway group can hold the root of a keyed family (Citadel Legs Base
      # has skins of its own) or sit under a record its prefix names (the
      # mobiGlas casings), and then joins that family rather than starting one.
      private def assign_worn_families(parsed, by_key)
        open = parsed.select do |item|
          WORN_EQUIPMENT_TYPES.include?(item[:equipment_type]) && [nil, item[:key]].include?(item[:family_key])
        end
        merged = {}

        open.group_by { |item| worn_family_key(item) }.each do |prefix, same_prefix|
          kinds = same_prefix.group_by { |item| kind(item) }
          base = by_key[prefix]
          if base && open.include?(base) && !same_prefix.include?(base) && kinds.key?(kind(base))
            kinds[kind(base)] += [base]
          end
          kinds = kinds.select { |_, members| members.size > 1 }

          kinds.each do |(_, item_type, slot), members|
            roots = members.select { |item| item[:family_key] }
            family_key = roots.first&.dig(:family_key) || (kinds.one? ? prefix : [prefix, slot || item_type].compact.join("_"))

            roots.drop(1).each { |other| merged[other[:key]] = family_key }
            members.each { |item| item[:family_key] = family_key }
          end
        end

        parsed.each { |item| item[:family_key] = merged.fetch(item[:family_key], item[:family_key]) }
      end

      private def kind(item)
        item.values_at(:equipment_type, :item_type, :slot)
      end

      private def base_key(item, by_key)
        segments = item[:key].split("_")

        (MIN_BASE_SEGMENTS...segments.size).each do |count|
          base = by_key[segments.first(count).join("_")]

          return base[:key] if base && same_kind?(base, item) && version_name?(item[:name], base[:name])
        end

        nil
      end

      # A skin keeps its base's name around a quoted one -- Gallant "Boneyard"
      # Rifle -- or adds a colour to it, and a colour sibling swaps the base's:
      # Tracer Laser Pointer Green under Tracer Laser Pointer Orange.
      private def version_name?(name, base_name)
        words = comparable_name(name).split
        base_words = comparable_name(base_name).split

        return true if words.first(base_words.size) == base_words
        return true if name.match?(QUOTED_NAME) && words.first == base_words.first

        words.size == base_words.size && words.size > 1 && words[0..-2] == base_words[0..-2]
      end

      # Some names carry a non-breaking space where others have a plain one.
      private def comparable_name(name)
        name.gsub(QUOTED_NAME, " ").gsub(/[[:space:]]+/, " ").strip.downcase
      end

      private def worn_family_key(item)
        item[:key].split("_")[0..-2].join("_")
      end

      private def same_kind?(base, item)
        base[:equipment_type] == item[:equipment_type] && base[:item_type] == item[:item_type]
      end

      private def skin_family(item)
        return item[:equipment_type] if CARRIED_EQUIPMENT_TYPES.include?(item[:equipment_type])
        return item[:item_type] if SUIT_ITEM_TYPES.include?(item[:item_type])

        item[:key].split("_").first(2).join("_")
      end

      private def parse_equipment(item)
        values = item[:values]
        attach_def = values.dig("Components", "SAttachableComponentParams", "AttachDef")

        return if attach_def.blank?

        name = localize_name(attach_def.dig("Localization", "Name"))

        return if value_or_nil(name).blank?

        key = item[:key]
        segments = key.split("_")
        described = describe(translate(attach_def.dig("Localization", "Description")))
        worn_type, slot = CHAR_TYPES[attach_def["Type"]]
        carried_type, carried_item_type = consumable_types(attach_def, key)

        if item.key?(:carried)
          picked_type, picked_item_type = carried_types(item, attach_def, values)

          return if picked_type.blank?
        end

        # The description header is written by hand and says "Assault Rifle"
        # where the record key only says "rifle", so it wins where it exists --
        # bar a picked record, whose header would call a flare a grenade, and a
        # garment whose header rates it as armour: a jacket listed under
        # clothing reads as a jacket, not as the one "Heavy Armor" among them.
        described_type = described[:item_type] unless worn_type == "clothing" && described[:item_type].to_s.end_with?("_armor")
        item_type = picked_item_type || described_type || carried_item_type || (item_type(segments, worn_type, slot) unless item.key?(:carried))

        {
          key:,
          ref: value_or_nil(values.dig("__ref")),
          name: value_or_nil(name),
          description: described[:description],
          equipment_type: picked_type || worn_type || carried_type || equipment_type(attach_def, item_type),
          slot:,
          item_type:,
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
          required_tags: (attach_def["RequiredTags"].to_s.split.presence if attach_def["Type"] == "WeaponAttachment"),
          ports: (attachment_ports(values).presence if attach_def["Type"] == "WeaponPersonal"),
          hidden: variant?(key),
          **occupancy(attach_def)
        }
      end

      # The ports a weapon takes attachments in -- magazine, optics, barrel,
      # underbarrel -- with the size range and tags an attachment has to meet,
      # and the attachment it ships with. Armour and gun cases carry
      # WeaponAttachment ports too, but those hold spare magazines rather than
      # fit them, which is why only a hand-held weapon or tool is asked.
      private def attachment_ports(values)
        defaults = Array.wrap(
          values.dig("Components", "SEntityComponentDefaultLoadoutParams", "loadout", "SItemPortLoadoutManualParams",
            "entries", "SItemPortLoadoutEntryParams")
        ).to_h { |entry| [entry["itemPortName"], value_or_nil(entry["entityClassName"])] }

        ports = Array.wrap(values.dig("Components", "SItemPortContainerComponentParams", "Ports", "SItemPortDef"))

        ports.filter_map do |port|
          sub_types = Array.wrap(port.dig("Types", "SItemPortDefTypes"))
            .select { |type| type["Type"] == "WeaponAttachment" }
            .flat_map { |type| Array.wrap(type.dig("SubTypes", "Enum")).filter_map { |sub_type| sub_type["value"].presence } }

          next if sub_types.empty?

          {
            name: port["Name"],
            sub_types:,
            min_size: port["MinSize"].to_i,
            max_size: port["MaxSize"].to_i,
            required_tags: port["RequiredPortTags"].to_s.split.presence,
            port_tags: port["PortTags"].to_s.split.presence,
            default: defaults[port["Name"]]
          }.compact
        end
      end

      private def equipment_type(attach_def, item_type)
        type = EQUIPMENT_TYPES[attach_def["Type"]]

        return type unless type == "weapon"
        return "tool" if TOOL_SUB_TYPES.include?(attach_def["SubType"]) || TOOL_ITEM_TYPES.include?(item_type)

        type
      end

      private def carried_types(item, attach_def, values)
        key = item[:key]
        picked = PICKED_RECORDS.find { |pattern, *| pattern.match?(key) }

        return picked.drop(1) if picked
        return if CARRIED_NOISE.match?(key)
        return if names_commodity?(attach_def, values)
        return SUIT_TYPES[attach_def["Type"]] || SUIT_TYPES[attach_def["SubType"]] if item[:carried] == :suit
        return [item[:carried]] if item[:carried].present?
        return carried_consumable_types(attach_def, key) if CONSUMABLE_ATTACH_TYPES.include?(attach_def["Type"])
        return [CARRIED_TYPES[attach_def["Type"]]] if CARRIED_TYPES.key?(attach_def["Type"])
        return ["sustenance"] if values.dig("Components", "SCItemConsumableParams").present?
        return [EQUIPMENT_TYPES[attach_def["Type"]]] if attach_def["Type"] == "WeaponPersonal"
        return ["flair"] if attach_def["SubType"].to_s.start_with?("Flair") || key.include?("_flair_")

        ["carryable"]
      end

      # A harvestable, the vent slug and SLAM carry a commodity's name, and the
      # commodities parser already loads them from the same records.
      private def names_commodity?(attach_def, values)
        names = [attach_def.dig("Localization", "Name")] +
          Array.wrap(values.dig("Components", "SCItemPurchasableParams")).map { |params| params["displayName"] }

        names.any? { |name| name.to_s.delete("@").downcase.start_with?(COMMODITY_NAME_PREFIX) }
      end

      # The Hacking chips a player carries are the cryptokeys -- Tigersclaw,
      # icePick, Walesko -- rather than the orbital keycards filed under the
      # same subtype in the consumables folder.
      private def carried_consumable_types(attach_def, key)
        return ["hacking_tool", "cryptokey"] if attach_def["SubType"] == "Hacking"

        consumable_types(attach_def, key)
      end

      private def consumable_types(attach_def, key)
        return unless CONSUMABLE_ATTACH_TYPES.include?(attach_def["Type"])

        carried_type, carried_item_type = CONSUMABLE_TYPES[attach_def["SubType"]]

        return if carried_type.blank?

        [carried_type, DATA_DRIVE_KEY.match?(key) ? "data_drive" : carried_item_type]
      end

      # How much room the piece takes when it is carried rather than worn. The
      # game states it twice: a volume, which is what a cargo grid and an
      # inventory charge for it, and the box it physically fills, which is the
      # ceiling once it snaps to a grid and stops sharing space with anything.
      #
      # One microSCU against a 0.15m cube is the value CIG leaves on a record
      # nobody has measured -- creature bodies and ship storage boxes carry the
      # same pair -- so it reads as unmeasured rather than as "vanishingly
      # small", and stays nil.
      private def occupancy(attach_def)
        micro_scu = micro_scu(attach_def["inventoryOccupancyVolume"] || {})
        dimensions = attach_def["inventoryOccupancyDimensions"] || {}
        x, y, z = %w[x y z].map { |axis| dimensions[axis].to_f }

        return {} if micro_scu <= UNMEASURED_MICRO_SCU && [x, y, z].all? { |side| side <= UNMEASURED_SIDE }

        {
          volume: (micro_scu / 1_000_000 if micro_scu > UNMEASURED_MICRO_SCU),
          volume_dimensions: ({x:, y:, z:} if [x, y, z].all?(&:positive?))
        }.compact
      end

      # Hand-held gear states its volume in microSCU; a crate you haul with a
      # tractor beam states it in whole SCU instead.
      private def micro_scu(volume)
        volume.dig("SMicroCargoUnit", "microSCU").to_f +
          volume.dig("SCentiCargoUnit", "centiSCU").to_f * 10_000 +
          volume.dig("SStandardCargoUnit", "standardCargoUnits").to_f * 1_000_000
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

        fields = header.join("\n").split("\n").reject(&:blank?).filter_map { |line|
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

      private def item_type(segments, worn_type, slot)
        case worn_type
        when "clothing" then GARMENTS[segments.drop(1).find { |segment| GARMENTS.key?(segment) }]
        when "undersuit" then (segments.include?("flightsuit") ? "flight_suit" : "undersuit")
        when "armor" then armor_item_type(segments, slot)
        else
          # A weapon mount's key names the mount before the maker.
          segment = (segments.first == "weaponmount") ? segments[2] : segments[1]

          ITEM_TYPES.fetch(segment, segment) if segment.present?
        end
      end

      private def armor_item_type(segments, slot)
        return "flight_helmet" if slot == "helmet" && segments.include?("flightsuit")

        weight = ARMOR_WEIGHTS[segments.find { |segment| ARMOR_WEIGHTS.key?(segment) }]

        "#{weight}_#{(slot == "backpack") ? "backpack" : "armor"}" if weight
      end

      private def load_equipment_data
        carried = CARRIED_PATHS.flat_map do |path, type|
          load_records(path).map { |item| item.merge(carried: type) }
        end

        SOURCE_PATHS.flat_map { |path| load_records(path) } + carried
      end

      private def load_records(path)
        Dir.glob("#{import_path}/#{path}/**/*.xml").map do |file|
          {
            key: File.basename(file, ".xml"),
            values: Hash.from_xml(File.read(file)).values.first
          }
        end
      end
    end
  end
end
