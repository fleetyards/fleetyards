# frozen_string_literal: true

module DressingRoom
  # The armour the game sells as a set, put together from its pieces: every
  # piece of one maker reads as the set's name with its slot word in it --
  # "ADP-mk4 Arms Woodland", "ADP-mk4 Core Woodland" -- and nothing records the
  # set itself. The keys do not help: they name the slot in a different place
  # per maker, and a few name a garment ("gys_jacket") rather than a core.
  class ArmorSets
    Piece = Struct.new(:slot, :slug, :name, :sc_key, :rigged)
    ArmorSet = Struct.new(:name, :manufacturer, :item_type, :item_type_label, :image_record, :pieces)

    SLOT_WORDS = {
      "helmet" => "Helmet",
      "torso" => "Core",
      "arms" => "Arms",
      "legs" => "Legs",
      "backpack" => "Backpack"
    }.freeze

    SLOT_WORD = /[[:space:]]+(?:#{SLOT_WORDS.values.join("|")})(?=[[:space:]]|\z)/

    # Fewer than three of the four body pieces is a helmet and a core that
    # happen to share a colour name, not a set.
    MIN_BODY_PIECES = 3

    BODY_SLOTS = %w[helmet torso arms legs].freeze

    # The model code after the line name ("-SL", "-CH-I") and the armour word,
    # which a backpack names differently from the armour it is sold with.
    MODEL_CODE = /\A([^[:space:]-]+)-[^[:space:]]+/
    ARMOR_WORD = /[[:space:]]+Armor(?=[[:space:]]|\z)/

    # Where a body piece's key names its slot: "kap_combat_light_helmet_02_03_01".
    KEY_SLOT_WORD = /_(?:helmet|core|arms|legs)_/

    # Pieces sold with a set that share neither its name nor its key, by the
    # key of the set's core.
    PAIRED_KEYS = {
      "kap_combat_light_core_01_02_01" => %w[thp_light_helmet_01_02_01 cds_combat_light_backpack_01_05_01],
      "kap_combat_light_core_02_03_01" => %w[vgl_utility_light_backpack_01_06_01]
    }.freeze

    PICTURE_ORDER = %w[torso helmet legs arms backpack].freeze

    # Stand-ins the game keeps under a sold piece's name, for the loadout
    # screens and the shop mannequins.
    STAND_IN_KEY = /\A(invisible|mannequin)_/

    def self.cache_key
      [
        "dressing-room/armor-sets/v4",
        ::ScData::Source.current.served.cache_key,
        ::Equipment.maximum(:updated_at)&.utc&.to_fs(:usec),
        ::EquipmentBuild.maximum(:updated_at)&.utc&.to_fs(:usec)
      ]
    end

    def all
      groups = pieces.group_by { |piece| [piece[:manufacturer_id], piece[:set_name]] }.values
      sets, strays = groups.partition { |members| (members.map { |member| member[:piece].slot }.uniq & BODY_SLOTS).size >= MIN_BODY_PIECES }

      strays = strays.flatten
      sets.each { |members| strays -= pair(members, strays) }
      strays.sort_by { |stray| preference(stray[:piece]) }.each { |stray| adopt(stray, sets) }

      sets.map { |members| build_set(members) }
        .sort_by { |set| [set.manufacturer&.name.to_s.downcase, set.name.downcase] }
    end

    # The game credits a piece of a set to another maker now and then -- most
    # Geist helmets are Gallenson's while the rest is Kilgore and Poole's -- so
    # a piece that forms no set of its own joins the one set of its name that
    # lacks its slot. A backpack's name strays further: "Geist Backpack Desert"
    # goes with "Geist Armor Desert", "Arden-CL Backpack Rime" with "Arden-SL
    # Rime".
    #
    # The key settles it before the name does: the Epoque II helmet is named
    # "Geist Armor Helmet Epoque", but its key is the Epoque II core's with the
    # slot word swapped.
    private def adopt(stray, sets)
      slot = stray[:piece].slot
      open = sets.select { |members| members.none? { |member| member[:piece].slot == slot } }

      family = key_family(stray[:piece].sc_key)
      homes = family ? open.select { |members| members.any? { |member| key_family(member[:piece].sc_key) == family } } : []
      homes = open.select { |members| members.first[:set_name] == stray[:set_name] } if homes.empty?
      if homes.empty? && slot == "backpack"
        homes = open.select { |members| line_name(members.first[:set_name]) == line_name(stray[:set_name]) }
      end

      homes.first << stray if homes.one?
    end

    private def pair(members, strays)
      keys = members.flat_map { |member| PAIRED_KEYS.fetch(member[:piece].sc_key.to_s, []) }
      paired = strays.select { |stray| keys.include?(stray[:piece].sc_key.to_s) }

      members.concat(paired)
      paired
    end

    private def key_family(sc_key)
      family = sc_key.to_s.sub(KEY_SLOT_WORD, "_")

      family unless family == sc_key.to_s
    end

    private def line_name(set_name)
      set_name.sub(MODEL_CODE, '\\1').gsub(ARMOR_WORD, "").squish
    end

    private def build_set(members)
      by_slot = members.group_by { |member| member[:piece].slot }
        .transform_values { |candidates| candidates.min_by { |candidate| preference(candidate[:piece]) } }

      core = by_slot["torso"] || by_slot.values.first

      ArmorSet.new(
        name: core[:set_name],
        manufacturer: core[:manufacturer],
        item_type: core[:item_type],
        item_type_label: ::Equipment.fact_label(:item_type, core[:item_type]),
        image_record: pictured_by(by_slot),
        pieces: SLOT_WORDS.keys.filter_map { |slot| by_slot[slot]&.dig(:piece) }
      )
    end

    # The core shows a set best, and every piece of it is rendered from the same
    # angle, so a set whose core has no render borrows another piece's before a
    # store photo, which would sit oddly among the renders.
    private def pictured_by(by_slot)
      records = PICTURE_ORDER.filter_map { |slot| by_slot[slot]&.dig(:record) }

      records.find { |record| record.angled_view.attached? } || records.find(&:angled_image_attr)
    end

    # A piece with a rig to wear in the dressing room before one without, and
    # the sold piece before a stand-in under its name.
    private def preference(piece)
      [piece.sc_key.to_s.match?(STAND_IN_KEY) ? 1 : 0, piece.rigged ? 0 : 1, piece.sc_key.to_s]
    end

    private def pieces
      rigged = ::ActiveStorage::Attachment.where(record_type: ::Equipment.name, name: "holo_rigged_male").select(:record_id)

      ::Equipment.visible
        .where(::Equipment.fact_sql(:equipment_type).eq("armor"))
        .where(::Equipment.fact_sql(:slot).in(SLOT_WORDS.keys.map { |slot| ::Equipment.slots[slot] }))
        .includes(:manufacturer, ::ItemViews::DISPLAY_IMAGE_PRELOAD)
        .select("equipment.*", "equipment_facts.name AS fact_name", "equipment_facts.slot AS fact_slot",
          "equipment_facts.item_type AS fact_item_type", "equipment.id IN (#{rigged.to_sql}) AS rigged")
        .filter_map { |record| piece(record) }
    end

    private def piece(record)
      name = record.fact_name.to_s.gsub(/[[:space:]]+/, " ").strip
      slot = ::Equipment.slots.key(record.fact_slot)
      set_name = name.gsub(SLOT_WORD, "").strip

      return if set_name == name || set_name.blank?

      {
        manufacturer_id: record.manufacturer_id,
        manufacturer: record.manufacturer,
        item_type: record.fact_item_type,
        set_name:,
        record:,
        piece: Piece.new(slot:, slug: record.slug, name:, sc_key: record.sc_key, rigged: record.rigged)
      }
    end
  end
end
