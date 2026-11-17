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

      def all
        return if galaxy.blank?

        save_items(systems, folder: "star_systems", key: :code)
        save_items(tunnels, folder: "jump_tunnels", key: :key)
      end

      def systems
        Array.wrap(galaxy["systems"]).map do |system|
          {
            code: code(system["system"]),
            name: system["name"],
            position: system["pos"].map(&:to_f),
            system_type: SYSTEM_TYPES[system["type"]],
            affiliations: Array.wrap(system["affiliation"]),
            in_game: in_game_systems.include?(system["system"])
          }
        end
      end

      def tunnels
        Array.wrap(galaxy["tunnels"]).map do |tunnel|
          entry = code(tunnel.dig("entry", "system"))
          exit = code(tunnel.dig("exit", "system"))

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

      private def in_game_systems
        @in_game_systems ||= begin
          file = "#{base_path}/#{PLACEMENTS_FILE}"

          File.exist?(file) ? Array.wrap(JSON.parse(File.read(file))["systems"]).map { |system| system["system"] }.to_set : Set.new
        end
      end

      private def galaxy
        @galaxy ||= begin
          file = "#{base_path}/#{GALAXY_FILE}"

          JSON.parse(File.read(file)) if File.exist?(file)
        end
      end
    end
  end
end
