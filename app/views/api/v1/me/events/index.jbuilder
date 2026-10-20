# frozen_string_literal: true

json.items do
  json.array! @items do |item|
    json.type item[:type]
    json.starts_at item[:starts_at].utc.iso8601

    if item[:type] == "fleet_event"
      fleet = item[:fleet]

      json.fleet do
        json.id fleet.id
        json.name fleet.name
        json.slug fleet.slug

        if fleet.logo.attached?
          json.logo do
            json.partial! "api/v1/shared/file", record: fleet, attr: :logo
          end
        end
      end

      json.fleet_event do
        json.partial! "api/v1/fleet_calendars/entry", entry: item[:entry], viewer_signups: item[:viewer_signups]
      end
    else
      json.game_event do
        json.partial! "api/v1/game_events/game_event", game_event: item[:game_event]
      end
    end
  end
end
