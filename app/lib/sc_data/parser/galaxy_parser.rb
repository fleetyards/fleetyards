# frozen_string_literal: true

module ScData
  module Parser
    # Every star system and jump tunnel on RSI's online starmap, which the
    # exporter saves beside each export. The game files only know the systems
    # it ships; RSI's map knows all ninety and where they sit. Its coordinates
    # come without a unit.
    #
    # A system is in the game when the export carries its object container.
    # Having a starmap record is not enough: Ellis has one and is not playable.
    class GalaxyParser < ScData::Parser::BaseParser
      GALAXY_FILE = "derived/galaxy.json"
      PLACEMENTS_FILE = ::ScData::Parser::StarmapParser::PLACEMENTS_FILE

      SYSTEM_TYPES = ::StarSystem::TYPES.index_by(&:upcase).freeze
      TUNNEL_SIZES = ::JumpTunnel::SIZES.index_by { |size| size[0].upcase }.freeze

      # Both folders are emptied first, so an export without the galaxy leaves
      # the loader nothing to load rather than the previous parse's files.
      def all
        clear_once("#{export_path}/star_systems")
        clear_once("#{export_path}/jump_tunnels")

        return if galaxy.blank?

        save_items(systems, folder: "star_systems", key: :code)
        save_items(tunnels, folder: "jump_tunnels", key: :key)
      end

      def systems
        Array.wrap(galaxy["systems"]).filter_map do |system|
          next unless position?(system["pos"]) && system["system"].present?

          {
            code: code(system["system"]),
            name: system["name"],
            position: system["pos"].map(&:to_f),
            system_type: SYSTEM_TYPES[system["type"]],
            affiliations: Array.wrap(system["affiliation"]),
            in_game: in_game_systems&.include?(system["system"])
          }
        end
      end

      def tunnels
        Array.wrap(galaxy["tunnels"]).filter_map do |tunnel|
          entry = code(tunnel.dig("entry", "system"))
          exit = code(tunnel.dig("exit", "system"))
          next if entry.blank? || exit.blank?

          {
            key: "#{entry}-#{exit}",
            entry_code: entry,
            exit_code: exit,
            size: TUNNEL_SIZES[tunnel["size"]],
            bidirectional: tunnel["direction"] == "B"
          }
        end
      end

      # The name the game files use, `stanton`, as fleet members carry it.
      private def code(name)
        name.to_s.upcase
      end

      private def position?(value)
        value.is_a?(Array) && value.size == 3 && value.all?(Numeric)
      end

      # Nil when the export has no placements, which says nothing about which
      # systems the game ships -- the loader keeps what it knew.
      private def in_game_systems
        return @in_game_systems if defined?(@in_game_systems)

        placements = read_json(PLACEMENTS_FILE)
        @in_game_systems = placements && Array.wrap(placements["systems"]).map { |system| system["system"] }.to_set
      end

      private def galaxy
        return @galaxy if defined?(@galaxy)

        @galaxy = read_json(GALAXY_FILE)
      end

      # RSI's map is optional to a parse: a file the exporter wrote half of is
      # treated as no file, rather than failing the game's patch with it.
      private def read_json(path)
        file = "#{base_path}/#{path}"
        return unless File.exist?(file)

        parsed = JSON.parse(File.read(file))
        parsed if parsed.is_a?(Hash)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
