# frozen_string_literal: true

json.array! @fleet_invite_urls, partial: "api/v1/fleet_invite_urls/fleet_invite_url", as: :fleet_invite_url
