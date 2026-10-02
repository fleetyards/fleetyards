module ScData
  module Loader
    class LocationsLoader < ::ScData::Loader::BaseLoader
      def all
        items = load_items("locations").select { |item| item["sc_key"].present? }
        @shared_names = items.group_by { |item| item["name"] }.select { |_name, group| group.size > 1 }.keys.to_set
        @by_key = {}

        loaded = parents_first(items).filter_map { |item| one(item)&.id }

        resolve_map_parents(items)

        retire_absent(Location, loaded)
        retire_absent_builds(LocationBuild, :location_id, loaded)

        prune_builds(LocationBuild)

        # The UEX sync matches a terminal to a place as it writes it, which
        # finds nothing for a place that arrived after the sync.
        stats[Terminal.name][:updated] += ::Uex::TerminalLocationMatcher.relink
        ::Uex::ShopLocationMatcher.relink

        ::ScData::Loader::LocationAppearances.new.apply
      end

      def one(item)
        location = Location.find_or_initialize_by(sc_key: item["sc_key"])
        location.name_shared = @shared_names.include?(item["name"]) if @shared_names

        Location.transaction do
          apply(location, row_params(item))
          apply_build(location, build_params(item))
        end

        (@by_key ||= {})[item["sc_key"]] = location
      end

      private def row_params(item)
        build_params(item).merge(
          sc_refs: Array.wrap(item["sc_refs"]).sort,
          parent: lookup(item["parent_key"]),
          system: lookup(item["system_key"]),
          mission_template_refs: Array.wrap(item["mission_template_refs"]).sort,
          version: sc_version
        )
      end

      private def build_params(item)
        {
          name: item["name"],
          description: item["description"],
          resources: Array.wrap(item["resources"]),
          kind: item["kind"],
          body_type: item["body_type"],
          game_type: item["game_type"],
          shown_on_starmap: item["shown_on_starmap"] || false,
          shown_with_parent_only: item["shown_with_parent_only"] || false,
          always_shown: item["always_shown"] || false,
          quantum_travel_destination: item["quantum_travel_destination"] || false
        }
      end

      private def lookup(key)
        return if key.blank?

        @by_key&.dig(key) || Location.find_by(sc_key: key)
      end

      # The map parent is drawn from anywhere in the tree -- Green is drawn
      # under the Stanton star and sits in the Ellis system -- so it is set once
      # every place has a row.
      private def resolve_map_parents(items)
        items.each do |item|
          location = @by_key[item["sc_key"]]
          next if location.nil?

          map_parent = lookup(item["map_parent_key"])
          next if location.map_parent_id == map_parent&.id

          apply_columns(location, map_parent_id: map_parent&.id)
        end
      end

      # Each place after the one it sits in, so a slug that names its parent
      # has one to name.
      private def parents_first(items)
        by_key = items.index_by { |item| item["sc_key"] }

        items.sort_by do |item|
          depth = 0
          seen = Set.new
          key = item["parent_key"]

          while key && by_key[key] && seen.add?(key)
            depth += 1
            key = by_key[key]["parent_key"]
          end

          [depth, item["sc_key"]]
        end
      end
    end
  end
end
