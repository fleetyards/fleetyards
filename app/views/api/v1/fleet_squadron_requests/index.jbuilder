# frozen_string_literal: true

json.array! @fleet_squadron_requests, partial: "api/v1/fleet_squadron_requests/fleet_squadron_request", as: :fleet_squadron_request
