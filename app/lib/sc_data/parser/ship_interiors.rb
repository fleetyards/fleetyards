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
      ROOMS_FILE = "derived/shiprooms.json"
      USABLE_PATHS = %w[entities/scitem/usables entities/scitem/ships/usableitems].freeze

      # Each anchor a bed's alignment slots name is a place to lie down. A bunk has a lower and an upper
      # one, a double bed one per side; the `_tv` anchors are a second pose on
      # a berth that already has its own.
      BERTH_ANCHOR = /\A\$anchor_bed(_top|_left|_right)?\z/

      def initialize(base_path:, import_path:)
        @base_path = base_path
        @import_path = import_path
      end

      def for(key)
        rooms = vehicles[key.to_s.downcase]&.dig("rooms")
        return {} if rooms.blank?

        classes = Hash.new(0)
        lockers = 0

        rooms.each do |room|
          room["classes"]&.each { |name, count| classes[name] += count.to_i }
          lockers += room.dig("contents", "locker").to_i
        end

        beds = classes.sum { |name, count| bed?(name) ? berths(name) * count : 0 }
        weapon_racks = classes.filter_map do |name, count|
          next unless weapon_rack?(name)

          {key: name, count:, slots: rack_slots(name)}
        end

        {
          beds: beds.positive? ? beds : nil,
          weapon_racks: weapon_racks.sort_by { |rack| rack[:key] }.presence,
          lockers: lockers.positive? ? lockers : nil
        }.compact
      end

      # A medical bed is a `Bed_` too; what sets it apart is the component
      # that treats and respawns.
      private def bed?(name)
        name.downcase.start_with?("bed_") && !usable(name)&.dig("Components")&.key?("MedBedComponentParams")
      end

      private def weapon_rack?(name)
        name.downcase.start_with?("weapon_rack")
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
            min_size: port["MinSize"]&.to_i,
            max_size: port["MaxSize"]&.to_i,
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
        @vehicles ||= begin
          file = "#{@base_path}/#{ROOMS_FILE}"
          rooms = File.exist?(file) ? JSON.parse(File.read(file))["vehicles"] : nil
          (rooms || {}).transform_keys(&:downcase)
        end
      end
    end
  end
end
