module ScData
  module Parser
    # Places a reader can open: star systems, planets, moons, stations, cities,
    # outposts and everything else the game's starmap carries a record for.
    #
    # A `StarMapObject`'s `parent` says how the in-game map draws a place, not
    # where it is. Levski hangs off the Nyx star because the map pins it at
    # system level, although it sits inside Delamar; the planets hang off their
    # star while the system record has no children at all. The tag database
    # knows the nesting -- Levski < Delamar < Nyx -- so a record's
    # `locationHierarchyTag` refines the parent where it points further down,
    # and the game's own parent is kept beside it as the map parent.
    class StarmapParser < ScData::Parser::BaseParser
      OVERRIDES_PATH = "config/sc_data/location_overrides.yml"

      STARMAP_PATH = "starmap/pu"
      TYPES_FILE = "starmap/starmapobjecttypes.records.xml"
      TAGS_FILE = "TagDatabase/tagdatabase.tagdatabase.records.xml"
      TEMPLATES_PATH = "missiondata/pu_locations/templates"

      # What the export writes where nobody has named a place yet. 148 of the
      # 2047 records in 4.10.1 resolve to one of these, or to nothing.
      FILLER_NAMES = ["<= UNINITIALIZED =>", "<= PLACEHOLDER =>"].freeze

      # A body's description lists what can be mined, harvested or hunted on
      # it, one section per kind: "Potential Ship Mineables:" and a name per
      # line, some with a note in brackets -- "Janalite (Caves only)". 21
      # bodies in 4.10.1 carry them. They are lifted out as data, and the
      # description keeps the prose.
      #
      # The colon is not always there: Daymar's "Potential Creatures" has none,
      # so a heading counts only with item lines under it.
      RESOURCE_HEADING = /\APotential (?<kind>[A-Za-z ]+):?\z/
      RESOURCE_NOTE = /\s*\((?<note>[^)]*)\)\s*\z/

      # Records that describe how a place is built rather than a place: the
      # template an outpost is cloned from, a barge spawned at Prospect Point,
      # the distress beacon a mission drops at MIC L1.
      NON_PLACE_KEYS = [/_template\z/i, /\Adynamicspawned/i, /\Amission_/i].freeze

      # A record the export names as unfinished: "WIP Refinery_0001".
      WIP_NAME = /\AWIP\b/

      KINDS = {
        "SolarSystem" => "system",
        "Star" => "star",
        "Planet" => "planet",
        "Moon" => "moon",
        "LandingZone" => "city",
        "Manmade" => "station",
        "Manmade_VisibleOnInteraction" => "station",
        "Outpost" => "outpost",
        "Outpost_InvalidQT" => "outpost",
        "Asteroid" => "asteroid",
        "Asteroid_ValidQT" => "asteroid",
        "Anomaly" => "anomaly",
        "JumpPoint" => "jump_point",
        "ManmadeJumpPoint" => "jump_point",
        "PointOfInterest" => "point_of_interest",
        "NavPoint" => "nav_point"
      }.freeze

      # The map icon says what a generic type does not: Levski is a `Manmade`
      # record drawn as a landing zone.
      ICON_KINDS = {"LandingZone" => "city", "Station" => "station", "Outpost" => "outpost"}.freeze

      # Too broad to say where a mission takes place. "Somewhere on Hurston" is
      # what most location templates resolve to, and it is not a link.
      BROAD_KINDS = %w[system star planet moon].freeze

      def self.overrides
        @overrides ||= begin
          path = Rails.root.join(OVERRIDES_PATH)

          path.exist? ? (YAML.safe_load_file(path) || {}) : {}
        end
      end

      def initialize(overrides: nil, **)
        super(**)

        @overrides = overrides
      end

      def overrides
        @overrides ||= self.class.overrides
      end

      def all
        save_items(locations, folder: "locations", key: :sc_key)
      end

      def locations
        @locations ||= begin
          places = place_records
          templates = template_owners(places)

          places.values.map do |place|
            serialize(place, places, templates[place[:key]])
          end
        end
      end

      private def serialize(place, places, template_refs)
        record = place[:record]

        {
          sc_key: place[:key],
          sc_refs: place[:refs],
          name: place[:name],
          description: place[:description],
          resources: place[:resources] || [],
          kind: place[:kind],
          game_type: record&.dig(:type),
          parent_key: place[:parent],
          map_parent_key: (place[:map_parent] if place[:map_parent] != place[:parent]),
          system_key: (system_of(place[:key], places) unless place[:kind] == "system"),
          shown_on_starmap: place[:shown_on_starmap],
          shown_with_parent_only: record ? record[:parent_only] : false,
          always_shown: record ? record[:permanent] : false,
          quantum_travel_destination: record ? record[:quantum_travel] : false,
          mission_template_refs: template_refs.to_a.sort
        }
      end

      # Keyed by record key: every later step names places that way, and a
      # merged or synthesised place has no single ref to go by.
      private def place_records
        places = {}

        records.each_value do |record|
          parent_ref = placed_parent(record)
          next if parent_ref == :drop

          places[record[:key]] = {
            key: record[:key],
            refs: [record[:ref]],
            record:,
            name: record[:name],
            description: record[:description],
            resources: record[:resources],
            kind: kind_of(record),
            parent: records[parent_ref]&.dig(:key),
            map_parent: records[record[:parent]]&.dig(:key),
            shown_on_starmap: !record[:hidden]
          }
        end

        place_stars(places)
        place_lagrange(places)
        place_at_keyed_bodies(places)
        place_foreign_systems(places)
        drop_unplaced(places)
        merge_overrides(places)
        fold_into_namesakes(places)
        resolve_map_parents(places)

        places
      end

      # `:drop` for a record that does not become a place, the ref of its parent
      # otherwise -- nil for a record at the top.
      #
      # A place under an unnamed one goes with it, unless its own tag says where
      # it belongs: Orison's floating platforms sit under an unnamed cluster
      # record and carry Orison's tag.
      private def placed_parent(record)
        return :drop unless named?(record)

        owner = tag_parent(record)
        owner = nil if owner && blocked?(owner)

        return owner ? owner[:ref] : :drop if blocked?(record)

        return owner[:ref] if owner && owner[:ref] != record[:parent] && ancestor_refs(owner).include?(record[:parent])

        record[:parent]
      end

      private def named?(record)
        named_refs.include?(record[:ref])
      end

      private def named_refs
        @named_refs ||= records.values.select { |record| place_name?(record) }.to_set { |record| record[:ref] }
      end

      private def place_name?(record)
        override = overrides[record[:key]].to_h
        return false if override["skip"]
        return false if NON_PLACE_KEYS.any? { |pattern| pattern.match?(record[:key]) }
        return false if sandbox_original?(record)

        record[:name].present? && !record[:name].match?(WIP_NAME)
      end

      # A hidden `..._Sandbox` base the export also ships a numbered copy of,
      # which is the one the map shows.
      private def sandbox_original?(record)
        record[:hidden] && record[:key].match?(/_sandbox\z/i) && record_keys.include?("#{record[:key]}_001".downcase)
      end

      private def record_keys
        @record_keys ||= records.values.to_set { |record| record[:key].downcase }
      end

      private def blocked?(record)
        ancestor_refs(record).any? { |ref| records[ref] && !named?(records[ref]) }
      end

      private def ancestor_refs(record)
        refs = []
        current = record

        while (parent = records[current[:parent]]) && refs.exclude?(parent[:ref])
          refs << parent[:ref]
          current = parent
        end

        refs
      end

      # The nearest place up the record's tag chain, other than itself.
      private def tag_parent(record)
        tag = record[:tag]
        seen = Set.new

        while tag && seen.add?(tag)
          owner = tag_owner(tag)
          return owner if owner && owner[:ref] != record[:ref]

          tag = tag_parents[tag]
        end

        nil
      end

      # The place a tag stands for. Planets carry no tag of their own while
      # their mining bases carry the planet's (`Stanton1`), so the record keyed
      # like the tag wins first; then the one carrying the tag that is named
      # like it (the floating platforms share "Orison" with Orison); then the
      # topmost of those carrying it, since children reuse their parent's tag.
      private def tag_owner(tag)
        @tag_owners ||= {}
        return @tag_owners[tag] if @tag_owners.key?(tag)

        name = tag_names[tag].to_s.downcase
        carriers = tagged_records[tag].to_a

        keyed = named_by_key[name]
        @tag_owners[tag] = if keyed&.one?
          keyed.first
        elsif (namesakes = carriers.select { |record| record[:name].to_s.downcase == name }).one?
          namesakes.first
        else
          refs = carriers.to_set { |record| record[:ref] }
          tops = carriers.reject { |record| ancestor_refs(record).any? { |ref| refs.include?(ref) } }

          tops.first if tops.one?
        end
      end

      private def tagged_records
        @tagged_records ||= records.values.select { |record| named?(record) && record[:tag] }.group_by { |record| record[:tag] }
      end

      private def named_by_key
        @named_by_key ||= records.values.select { |record| named?(record) }.group_by { |record| record[:key].downcase }
      end

      # The planets hang off the star and the system record has no children,
      # so the star goes inside the system of the same name.
      # The game draws Lagrange points and the rest stops at them under the
      # star, and the tags do not say better: Stanton's points are tagged
      # `ARC_L1 < ARC < LagrangePoints`, and no record is called ARC. The keys
      # do. A point is keyed after its planet -- `Stanton3_L1` is ArcCorp's L1
      # -- and a rest stop after the point, `RR_<code>_L<n>`, with the code the
      # point's own name prefix (HUR, for "HUR L1") or the planet key's initial
      # and number (P2, for `Pyro2`). The star stays the map parent.
      private def place_lagrange(places)
        points = places.values.filter_map do |place|
          match = place[:key].match(/\A(?<planet>[A-Za-z]+\d+)_L(?<number>\d)\z/)
          next unless match && places[match[:planet]]&.dig(:kind) == "planet"

          place[:parent] = match[:planet]
          {key: place[:key], planet: match[:planet], number: match[:number], prefix: place[:name].to_s.split.first}
        end

        places.each_value do |place|
          match = place[:key].match(/\ARR_(?<code>[A-Za-z0-9]+)_L(?<number>\d)\z/)
          next unless match

          point = points.find do |candidate|
            candidate[:number] == match[:number] &&
              [candidate[:prefix], "#{candidate[:planet][0]}#{candidate[:planet][/\d+\z/]}"].include?(match[:code])
          end

          place[:parent] = point[:key] if point
        end
      end

      # Untagged and drawn under the star, with where it is only in its key.
      # Wikelo's Dasi Station is `TheCollectorAsteroid_Stanton1`, at Hurston.
      # A key with a letter on another's goes inside it, the way `Stanton1a` is
      # Hurston's first moon: the hangars `..._Executive_001a` to `c` are in
      # the asteroid base `..._Executive_001`. The star stays the map parent.
      private def place_at_keyed_bodies(places)
        places.each_value do |place|
          star = places[place[:parent]]
          next unless star&.dig(:kind) == "star"

          body = places[place[:key][/_([A-Za-z]+\d+[a-z]?)\z/, 1]]
          body = nil unless body && body[:parent] == star[:key] && %w[planet moon].include?(body[:kind])
          body ||= places[place[:key][/\A(.+\d)[a-z]\z/, 1]]&.then { |base| base if base[:parent] == star[:key] }

          place[:parent] = body[:key] if body
        end
      end

      private def place_stars(places)
        places.each_value do |place|
          next unless place[:kind] == "star" && place[:parent].nil?

          system_key = place[:key].sub(/Star\z/, "SolarSystem")
          place[:parent] = system_key if places[system_key]
        end
      end

      # A record keyed after a system that is not the one it sits in. Green --
      # `Ellis3`, Ellis III -- hangs off the Stanton star; the export has no
      # record for Ellis, so the system is built from its translation.
      private def place_foreign_systems(places)
        places.values.each do |place|
          prefix = place[:key][/\A([A-Za-z]+)\d/, 1]
          next if prefix.nil?

          system_key = "#{prefix}SolarSystem"
          next if system_of(place[:key], places) == system_key

          system_name = localize(prefix)
          next unless system_name.to_s.end_with?(" System")

          places[system_key] ||= {
            key: system_key,
            refs: [],
            record: nil,
            name: system_name,
            description: translate("@#{prefix}_Desc"),
            kind: "system",
            parent: nil,
            map_parent: nil,
            shown_on_starmap: false
          }

          place[:parent] = system_key
        end
      end

      # Mission markers the game places at run time hang under no system --
      # Quantum Beacon, Distress Beacon, Salvage.
      private def drop_unplaced(places)
        places.delete_if do |key, _place|
          root = root_of(key, places)

          places[root].nil? || places[root][:kind] != "system"
        end
      end

      private def merge_overrides(places)
        overrides.each do |key, override|
          next unless places[key]

          Array.wrap(override.to_h["merge"]).each { |copy| absorb(places, copy, into: key) }
        end
      end

      # A record named like the place it sits in is a label inside it: "Vision
      # Center" under Vision Center under Orison.
      private def fold_into_namesakes(places)
        loop do
          key, place = places.find { |_key, candidate| (parent = places[candidate[:parent]]) && parent[:name] == candidate[:name] }
          break if key.nil?

          absorb(places, key, into: place[:parent])
        end
      end

      private def absorb(places, key, into:)
        copy = places.delete(key)
        return if copy.nil?

        target = places[into]
        target[:refs] |= copy[:refs]
        target[:shown_on_starmap] ||= copy[:shown_on_starmap]

        places.each_value { |place| place[:parent] = into if place[:parent] == key }

        (@absorbed ||= {})[key] = into
      end

      # Up the game's own parent chain to the nearest place that was kept.
      private def resolve_map_parents(places)
        places.each_value do |place|
          key = place[:map_parent]
          seen = Set.new

          while key && !places[key] && seen.add?(key)
            key = @absorbed&.dig(key) || records_by_key[key]&.then { |record| records[record[:parent]]&.dig(:key) }
          end

          place[:map_parent] = key
        end
      end

      private def records_by_key
        @records_by_key ||= records.values.index_by { |record| record[:key] }
      end

      private def root_of(key, places)
        seen = Set.new

        key = places[key][:parent] while places[key]&.dig(:parent) && seen.add?(key)

        key
      end

      private def system_of(key, places)
        root = root_of(key, places)

        root if places[root]&.dig(:kind) == "system"
      end

      private def kind_of(record)
        return "jump_point" if record[:key].start_with?("JumpPoint_")

        ICON_KINDS[record[:icon]] || KINDS[record[:type]] || "other"
      end

      # Each mission location template links to the place its most specific
      # location tag stands for, and only when that place is specific -- not a
      # whole star, planet or moon.
      private def template_owners(places)
        owners = Hash.new { |all, key| all[key] = Set.new }

        templates.each do |template|
          tag = template[:tags].select { |id| tag_owner(id) }.max_by { |id| tag_depth(id) }
          next if tag.nil?

          key = resolve_key(tag_owner(tag)[:key], places)
          next if key.nil? || BROAD_KINDS.include?(places[key][:kind])

          owners[key] << template[:ref]
        end

        owners
      end

      private def resolve_key(key, places)
        seen = Set.new

        key = @absorbed[key] while key && !places[key] && @absorbed&.key?(key) && seen.add?(key)

        key if places[key]
      end

      private def tag_depth(tag)
        depth = 0
        seen = Set.new

        depth += 1 while (tag = tag_parents[tag]) && seen.add?(tag)

        depth
      end

      private def records
        @records ||= load_data(STARMAP_PATH).each_with_object({}) do |item, all|
          values = item[:values]
          next unless values.is_a?(Hash)

          ref = value_or_nil(values["__ref"])
          next if ref.nil?

          type = object_types[values["type"]].to_h
          override = overrides[item[:key]].to_h

          all[ref] = {
            key: item[:key],
            ref:,
            name: override["name"] || place_name(values["name"]),
            description: description_text(values["description"]),
            resources: description_resources(values["description"]),
            type: type[:name],
            icon: values["navIcon"],
            parent: value_or_nil(values["parent"]),
            tag: value_or_nil(values["locationHierarchyTag"]),
            hidden: values["hideInStarmap"] == "1",
            parent_only: values["onlyShowWhenParentSelected"] == "1",
            permanent: values["overridePermanent"] == "True",
            quantum_travel: type[:quantum_travel] || false
          }
        end
      end

      private def place_name(key)
        name = localize_name(key)

        name.presence unless FILLER_NAMES.include?(name)
      end

      private def place_description(key)
        description = translate(key)

        description.presence unless FILLER_NAMES.include?(description)
      end

      private def description_sections(key)
        text = place_description(key)
        return [] if text.nil?

        # The export writes line breaks as a literal backslash-n.
        text.gsub("\\n", "\n").split(/\n\s*\n/).map { |block| block.strip.lines.map(&:strip) }
      end

      private def description_text(key)
        prose = description_sections(key).reject { |lines| resource_section?(lines) }
        return if prose.empty?

        prose.map { |lines| lines.join("\\n") }.join("\\n\\n")
      end

      private def resource_section?(lines)
        lines.size > 1 && lines.first.to_s.match?(RESOURCE_HEADING)
      end

      private def description_resources(key)
        description_sections(key).filter_map do |lines|
          next unless resource_section?(lines)

          match = lines.first.match(RESOURCE_HEADING)

          items = lines.drop(1).reject(&:empty?).map do |line|
            note = line.match(RESOURCE_NOTE)

            {name: line.sub(RESOURCE_NOTE, ""), note: note && note[:note]}
          end

          {kind: match[:kind].parameterize(separator: "_"), items:} if items.any?
        end
      end

      private def object_types
        @object_types ||= records_in(TYPES_FILE).each_with_object({}) do |(key, values), all|
          next unless key.start_with?("StarMapObjectType.") && values.is_a?(Hash)

          all[values["__ref"]] = {
            name: values["name"],
            quantum_travel: values["validQuantumTravelDestination"] == "1"
          }
        end
      end

      private def templates
        @templates ||= load_data(TEMPLATES_PATH).filter_map do |item|
          values = item[:values]
          next unless values.is_a?(Hash)

          data = values["locationData"].to_h
          next if data["disabled"] == "1"

          ref = value_or_nil(values["__ref"])
          next if ref.nil?

          tags = Array.wrap(data.dig("generalTags", "tags", "Reference")).filter_map do |reference|
            value_or_nil(reference["value"]) if reference.is_a?(Hash)
          end

          {ref:, tags:}
        end
      end

      private def tag_names
        tag_tree
        @tag_names
      end

      private def tag_parents
        tag_tree
        @tag_parents
      end

      private def tag_tree
        return if @tag_names

        @tag_names = {}
        @tag_parents = {}

        records_in(TAGS_FILE).each do |key, value|
          next unless key.start_with?("Tag.")

          Array.wrap(value).each do |tag|
            next unless tag.is_a?(Hash)

            @tag_names[tag["__ref"]] = tag["tagName"]

            Array.wrap(tag.dig("children", "Reference")).each do |child|
              @tag_parents[child["value"]] = tag["__ref"] if child.is_a?(Hash)
            end
          end
        end
      end

      # A file of many records under one `<Records>` root, keyed by element name.
      private def records_in(path)
        file = "#{import_path}/#{path}"
        return {} unless File.exist?(file)

        Hash.from_xml(File.read(file)).values.first.to_h
      end
    end
  end
end
