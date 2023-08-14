# frozen_string_literal: true

json.cache! ["v1", station] do
  json.partial!("admin/api/v1/stations/base", station:)
  json.habitation_counts do
    json.array! station.habitation_counts, partial: "api/v1/habitation_counts/base", as: :habitation_count
  end
  json.dock_counts do
    json.array! station.dock_counts, partial: "api/v1/dock_counts/base", as: :dock_count
  end
  json.partial! "api/shared/dates", record: station
end
