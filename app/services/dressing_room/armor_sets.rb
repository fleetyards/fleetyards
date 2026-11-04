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

    PICTURE_ORDER = %w[torso helmet legs arms backpack].freeze

    # Stand-ins the game keeps under a sold piece's name, for the loadout
    # screens and the shop mannequins.
    STAND_IN_KEY = /\A(invisible|mannequin)_/

    def self.cache_key
      [
        "dressing-room/armor-sets/v2",
        ::ScData::Source.current.served.cache_key,
        ::Equipment.maximum(:updated_at)&.utc&.to_fs(:usec),
        ::EquipmentBuild.maximum(:updated_at)&.utc&.to_fs(:usec)
      ]
    end

    def all
      pieces.group_by { |piece| [piece[:manufacturer_id], piece[:set_name]] }
        .filter_map { |_, members| build_set(members) }
        .sort_by { |set| [set.manufacturer&.name.to_s.downcase, set.name.downcase] }
    end

    private def build_set(members)
      by_slot = members.group_by { |member| member[:piece].slot }
        .transform_values { |candidates| candidates.min_by { |candidate| preference(candidate[:piece]) } }

      return if (by_slot.keys & BODY_SLOTS).size < MIN_BODY_PIECES

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
