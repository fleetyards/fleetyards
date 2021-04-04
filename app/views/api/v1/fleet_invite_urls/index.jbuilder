# frozen_string_literal: true

json.array! @fleet_invite_urls, partial: 'api/v1/fleet_invite_urls/minimal', as: :fleet_invite_url
