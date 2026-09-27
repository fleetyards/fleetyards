# frozen_string_literal: true

module Uex
  class TerminalSyncer
    TERMINAL_TYPE = "commodity"

    # How many of the terminals we hold as available a feed must still list
    # before its omissions are believed. Half the terminals closing between two
    # runs is not a patch; a feed that came back short looks exactly like that.
    MIN_RETENTION = 0.5

    # `terminals` holds every terminal the feed listed, keyed by UEX id, so the
    # price and route syncers can resolve rows without a second lookup.
    # `live_ids` are the terminals to treat as open: the listed ones, plus the
    # omitted ones a short feed could not retire.
    Result = Struct.new(:created, :updated, :retired, :terminals, :live_ids, :short_feed) do
      def to_s
        "created=#{created} updated=#{updated} retired=#{retired}#{" short_feed" if short_feed}"
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

      listed_ids = rows.pluck("id")
      short_feed = short_feed?(listed_ids)

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
      omitted = Terminal.available.where.not(uex_id: listed_ids)
      retired = short_feed ? 0 : omitted.update_all(available: false, updated_at: Time.current)
      report_short_feed(listed_ids.size) if short_feed

      live_ids = terminals.values.map(&:id).to_set
      live_ids.merge(omitted.pluck(:id)) if short_feed

      Result.new(created:, updated:, retired:, terminals:, live_ids:, short_feed:)
    end

    private def short_feed?(listed_ids)
      held = Terminal.available.pluck(:uex_id)
      return false if held.empty?

      (held & listed_ids).size < held.size * MIN_RETENTION
    end

    private def report_short_feed(listed)
      message = "UEX listed #{listed} commodity terminals, under half the #{Terminal.available.count} we hold; retired none"

      Rails.logger.warn("[#{self.class.name}] #{message}")
      Appsignal.report_error(Uex::Error.new(message))
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
