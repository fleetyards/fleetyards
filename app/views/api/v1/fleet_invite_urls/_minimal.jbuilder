# frozen_string_literal: true

json.cache! ['v1', fleet_invite_url] do
  json.partial! 'api/v1/fleet_invite_urls/base', fleet_invite_url: fleet_invite_url
  json.partial! 'api/shared/dates', record: fleet_invite_url
end
