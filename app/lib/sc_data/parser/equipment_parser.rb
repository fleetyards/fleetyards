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

      # Tints, store and collector editions, and the marketing and template
      # records that never reach a player. They carry their own key, so they
      # load as rows, but a picker listing twelve Pyro RYT Multi-Tools is not
      # useful -- Component solves the same problem the same way.
      VARIANT_SUFFIX = /_(tint|collector|store|mr|sf|prop|template|black|mat|tan)\d*\z/

      def all
        save_items(equipment, folder: "equipment")
      end

      def equipment
        load_equipment_data.filter_map { |item| parse_equipment(item) }
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

        {
          key:,
          ref: value_or_nil(values.dig("__ref")),
          name: value_or_nil(name),
          description: described[:description],
          equipment_type: EQUIPMENT_TYPES[attach_def["Type"]],
          # The description header is written by hand and says "Assault Rifle"
          # where the record key only says "rifle", so it wins where it exists.
          item_type: described[:item_type] || item_type(segments),
          weapon_class: described[:weapon_class] || WEAPON_CLASSES.find { |klass| segments.include?(klass) },
          rate_of_fire: described[:rate_of_fire],
          range: described[:range],
          storage: described[:storage],
          sub_type: value_or_nil(attach_def["SubType"]),
          size: value_or_nil(attach_def["Size"]),
          grade: value_or_nil(attach_def["Grade"]),
          manufacturer_ref: value_or_nil(attach_def["Manufacturer"]),
          tags: attach_def["Tags"].to_s.split,
          hidden: VARIANT_SUFFIX.match?(key)
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
          storage: numeric(fields["magazine size"] || fields["capacity"] || fields["battery size"])
        }
      end

      # A short label before the colon on every line. The length bound keeps a
      # prose sentence that happens to contain a colon out of the spec block.
      private def spec_block?(block)
        lines = block.split("\n").reject(&:blank?)

        lines.any? && lines.all? { |line| line.match?(/\A[^:]{1,30}:/) }
      end

      private def numeric(value)
        return if value.blank?

        number = value[/[\d.]+/]

        number&.to_d
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
