# frozen_string_literal: true

module ScData
  module Loader
    # RSI's map of every system and the tunnels between them. The rows are not
    # versioned: RSI's map follows no game build. Only the environment readers
    # get by default writes them, since which systems are in the game is a
    # build's answer -- a ptu load must not light up a system live lacks.
    #
    # A parse without the galaxy -- the exporter could not reach RSI -- leaves
    # what is there.
    class GalaxyLoader < ::ScData::Loader::BaseLoader
      def all
        return unless default_environment?

        items = load_items("star_systems")
        return if items.empty?

        StarSystem.transaction do
          systems = items.to_h { |item| [item["code"], one(item)] }

          StarSystem.where.not(id: systems.values.map(&:id)).destroy_all

          load_tunnels(systems)
        end
      end

      # Nil `in_game` is a parse that could not tell, and leaves the row's.
      def one(item)
        system = StarSystem.find_or_initialize_by(code: item["code"])

        apply(system, {
          name: item["name"],
          position: item["position"],
          system_type: item["system_type"],
          affiliations: Array.wrap(item["affiliations"]),
          in_game: item["in_game"].nil? ? system.in_game : item["in_game"]
        })
      end

      # No tunnels at all is a map that failed to say, not one without any.
      private def load_tunnels(systems)
        items = load_items("jump_tunnels")
        return if items.empty?

        tunnels = items.filter_map { |item| tunnel(item, systems) }

        JumpTunnel.where.not(id: tunnels.map(&:id)).delete_all
      end

      private def tunnel(item, systems)
        entry = systems[item["entry_code"]]
        exit = systems[item["exit_code"]]
        return if entry.nil? || exit.nil?

        apply(JumpTunnel.find_or_initialize_by(entry_system: entry, exit_system: exit), {
          size: item["size"],
          bidirectional: item["bidirectional"]
        })
      end
    end
  end
end
