# frozen_string_literal: true

json.array! @tour_join_requests, partial: "api/v1/tour_join_requests/tour_join_request", as: :tour_join_request
