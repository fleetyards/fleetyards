# frozen_string_literal: true

module Uex
  class TerminalSyncer
    TERMINAL_TYPE = "commodity"

    # `terminals` holds every terminal the feed listed, keyed by UEX id, so the
    # price and route syncers can resolve rows without a second lookup.
    Result = Struct.new(:created, :updated, :retired, :terminals) do
      def to_s
        "created=#{created} updated=#{updated} retired=#{retired}"
      end
    end

    def initialize(client: Uex::Client.new)
      @client = client
    end

    def run
      rows = @client.terminals.select { |row| row["type"] == TERMINAL_TYPE }

      # An empty feed would otherwise retire every terminal, and every price and
      # route hanging off one with it.
      raise Uex::Error, "UEX returned no commodity terminals; refusing to sync an empty snapshot" if rows.empty?

      created = 0
      updated = 0
      terminals = {}

      Terminal.transaction do
        existing = Terminal.where(uex_id: rows.pluck("id")).index_by(&:uex_id)

        rows.each do |row|
          terminal = existing[row["id"]] || Terminal.new(uex_id: row["id"])
          terminal.assign_attributes(attributes(row))
          terminals[row["id"]] = terminal
          next unless terminal.changed?

          terminal.new_record? ? created += 1 : updated += 1
          terminal.save!
        end
      end

      # Kept rather than deleted: prices and routes refer to them, and UEX
      # brings terminals back when a patch restores a location.
      retired = Terminal.available.where.not(uex_id: rows.pluck("id")).update_all(available: false, updated_at: Time.current)

      Result.new(created:, updated:, retired:, terminals:)
    end

    private def attributes(row)
      {
        name: row["name"].to_s.strip,
        nickname: row["nickname"].presence,
        display_name: row["displayname"].presence,
        code: row["code"].presence,
        star_system: row["star_system_name"].presence,
        planet: row["planet_name"].presence,
        orbit: row["orbit_name"].presence,
        moon: row["moon_name"].presence,
        space_station: row["space_station_name"].presence,
        city: row["city_name"].presence,
        outpost: row["outpost_name"].presence,
        # UEX writes 0 for a terminal nobody has measured yet.
        max_container_size: row["max_container_size"].to_i.positive? ? row["max_container_size"].to_i : nil,
        has_freight_elevator: row["has_freight_elevator"] == 1,
        has_loading_dock: row["has_loading_dock"] == 1,
        has_docking_port: row["has_docking_port"] == 1,
        player_owned: row["is_player_owned"] == 1,
        available: row["is_available_live"] == 1,
        contact_url: web_url(row["contact_url"]),
        source_updated_at: row["date_modified"].to_i.positive? ? Time.zone.at(row["date_modified"].to_i) : nil
      }
    end

    private def web_url(url)
      url.presence if url.to_s.match?(%r{\Ahttps?://})
    end
  end
end
