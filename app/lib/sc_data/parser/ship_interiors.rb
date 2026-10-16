module ScData
  module Parser
    # The furniture a vehicle's rooms hold: where its crew sleeps, what its
    # weapon racks take and how many armour lockers it carries.
    #
    # The export's `derived/shiprooms.json` lists, per vehicle record, every
    # room the ship brings and the usable entities placed in it by class name.
    # It counts items, not what they hold, so the berths of a bed and the slots
    # of a rack are read from the usable's own record. An interior from before
    # the rework of its ship places none of these entities at all, which is why
    # a vehicle with nothing found gets nothing rather than zeros.
    class ShipInteriors
      # Written by the exporter from the object containers in `Data.p4k`, which
      # the raw tree does not carry: the rooms a vehicle or module brings and
      # what stands in them. Exports before it existed have no file.
      ROOMS_FILE = "derived/shiprooms.json"
      USABLE_PATHS = %w[entities/scitem/usables entities/scitem/ships/usableitems].freeze

      # Each anchor a bed's alignment slots name is a place to lie down. A bunk
      # has a lower and an upper one, a double bed one per side; the `_tv`
      # anchors are a second pose on a berth that already has its own.
      BERTH_ANCHOR = /\A\$anchor_bed(_top|_left|_right)?\z/

      # What a usable is, as the export classifies it: by the animation tag its
      # actor uses, except a medical bed, which carries the component that
      # treats and respawns. A `Cargo_Slot_*` is a weapon rack by that tag even
      # though its name says otherwise. The prefixes stand in only when the
      # record is missing.
      KINDS = %w[bed weapon_rack locker].freeze
      KIND_PREFIXES = {"bed_" => "bed", "weapon_rack" => "weapon_rack", "locker_" => "locker"}.freeze

      def self.read_rooms(base_path, section)
        file = "#{base_path}/#{ROOMS_FILE}"
        rooms = File.exist?(file) ? JSON.parse(File.read(file))[section] : nil
        (rooms || {}).transform_keys(&:downcase)
      end

      def initialize(base_path:, import_path:)
        @base_path = base_path
        @import_path = import_path
      end

      def for(key)
        rooms = vehicles[key.to_s.downcase]&.dig("rooms")
        return {} if rooms.blank?

        classes = Hash.new(0)
        rooms.each { |room| room["classes"]&.each { |name, count| classes[name] += count.to_i } }
        by_kind = classes.group_by { |name, _count| kind(name) }

        beds = by_kind.fetch("bed", []).sum { |name, count| berths(name) * count }
        lockers = by_kind.fetch("locker", []).sum { |_name, count| count }
        weapon_racks = by_kind.fetch("weapon_rack", []).map do |name, count|
          {key: name, count:, slots: rack_slots(name)}
        end

        {
          beds: beds.positive? ? beds : nil,
          weapon_racks: weapon_racks.sort_by { |rack| rack[:key] }.presence,
          lockers: lockers.positive? ? lockers : nil
        }.compact
      end

      private def kind(name)
        components = usable(name)&.dig("Components")
        return KIND_PREFIXES.find { |prefix, _kind| name.downcase.start_with?(prefix) }&.last if components.nil?
        return "medbed" if components.key?("MedBedComponentParams")

        tag = Array.wrap(components["SActorUsableParams"]).first&.dig("fragmentTag")
        tag if KINDS.include?(tag)
      end

      # A bed whose record is missing, or names no anchor, still sleeps one.
      private def berths(name)
        values = usable(name)
        return 1 if values.nil?

        anchors = helper_names(values).grep(BERTH_ANCHOR).uniq.size
        anchors.positive? ? anchors : 1
      end

      private def rack_slots(name)
        ports = usable(name)&.dig("Components", "SItemPortContainerComponentParams", "Ports", "SItemPortDef")

        Array.wrap(ports).map do |port|
          {
            min_size: port["MinSize"].to_i,
            max_size: port["MaxSize"].to_i,
            types: Array.wrap(port.dig("Types", "SItemPortDefTypes")).map do |type|
              {
                type: type["Type"],
                sub_types: Array.wrap(type.dig("SubTypes", "Enum")).filter_map { |sub_type| sub_type["value"].presence }
              }
            end,
            required_tags: port["RequiredPortTags"].to_s.split.presence
          }.compact
        end
      end

      private def helper_names(value, found = [])
        case value
        when Hash
          found << value["helperName"] if value["helperName"].is_a?(String)
          value.each_value { |child| helper_names(child, found) }
        when Array
          value.each { |child| helper_names(child, found) }
        end

        found
      end

      private def usable(name)
        @usables ||= {}
        return @usables[name] if @usables.key?(name)

        file = usable_files[name.downcase]
        @usables[name] = file && Hash.from_xml(File.read(file)).values.first
      end

      # Class name to record file. The root element carries the class name, and
      # it is always on the first line.
      private def usable_files
        @usable_files ||= USABLE_PATHS.flat_map { |path| Dir.glob("#{@import_path}/#{path}/**/*.xml") }.each_with_object({}) do |file, index|
          root = File.open(file, &:readline)[/\A<\w+\.(\w+)/, 1]
          index[root.downcase] ||= file if root
        rescue EOFError
          next
        end
      end

      private def vehicles
        @vehicles ||= self.class.read_rooms(@base_path, "vehicles")
      end
    end
  end
end
