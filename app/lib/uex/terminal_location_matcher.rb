# frozen_string_literal: true

module Uex
  # The place a UEX terminal is at. UEX names it as a string per level --
  # system, planet, moon, station, city, outpost -- and the most specific one
  # set is matched by name against the places in that system.
  #
  # 157 of the 161 commodity terminals resolve. The rest have nothing to match:
  # Port Olisar is gone from the game, "Admin - UEX Station" names no place,
  # and UEX files Grim HEX's two under "Green Imperial Housing Exchange", a
  # name the starmap does not use.
  class TerminalLocationMatcher
    LEVELS = %i[outpost city space_station moon planet orbit].freeze

    # Every terminal this matcher has an answer for, rewritten where it moved.
    # Run after a load of the places, which may have arrived after the sync.
    def self.relink(terminals = Terminal.all)
      matcher = new

      terminals.find_each.count do |terminal|
        location_id = matcher.match(terminal)
        next false if terminal.location_id == location_id

        terminal.update_columns(location_id:)
      end
    end

    def match(terminal)
      level = LEVELS.find { |attribute| terminal.public_send(attribute).present? }
      return if level.nil? || terminal.star_system.blank?

      name = terminal.public_send(level)
      system = normalize(terminal.star_system)
      context = [terminal.moon, terminal.planet].compact.map { |value| normalize(value) }

      candidates = places.fetch([system, normalize(name)], [])
      candidates = places.fetch([system, normalize(name.sub(/\s+station\z/i, ""))], []) if candidates.empty?
      candidates = prefixed(system, normalize(name), context) if candidates.empty?

      pick(candidates, context)&.dig(:id)
    end

    # The candidate under the moon the terminal names, then under its planet,
    # when the name alone is shared.
    private def pick(candidates, context)
      return candidates.first if candidates.one?

      context.each do |level|
        within = candidates.select { |place| place[:ancestors].include?(level) }
        return within.first if within.one?
      end

      nil
    end

    # UEX shortens a name the starmap spells out: "Deakins Research" is
    # "Deakins Research Outpost".
    private def prefixed(system, name, context)
      return [] if name.length < 4

      places.each_pair
        .select { |(place_system, place_name), _| place_system == system && place_name.start_with?(name) }
        .flat_map(&:last)
        .select { |place| context.empty? || (place[:ancestors] & context).any? }
    end

    # "Pyro Gateway (Stanton)" is Pyro Gateway, in the system UEX already
    # names separately.
    private def normalize(value)
      value.to_s.downcase.sub(/\s*\([^)]*\)\s*\z/, "").gsub(/[^a-z0-9]/, "")
    end

    private def places
      @places ||= begin
        rows = Location.current_version.pluck(:id, :name, :parent_id, :kind).to_h { |id, *rest| [id, rest] }

        rows.each_with_object({}) do |(id, (name, parent_id, kind)), index|
          next if kind == "system"

          ancestors = []
          current = parent_id
          while current && rows[current] && ancestors.size < 10
            ancestors << rows[current][0]
            current = rows[current][1]
          end

          system = ancestors.last.to_s.sub(/ System\z/, "")
          (index[[normalize(system), normalize(name)]] ||= []) << {id:, ancestors: ancestors.map { |ancestor| normalize(ancestor) }}
        end
      end
    end
  end
end
