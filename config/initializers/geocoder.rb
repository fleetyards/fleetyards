# frozen_string_literal: true

Geocoder.configure(
  lookup: :nominatim,
  http_headers: {"User-Agent" => "FleetYards (fleetyards.net)"},
  units: :km,
  cache: Rails.cache,
  cache_options: {expiration: 1.day}
)
