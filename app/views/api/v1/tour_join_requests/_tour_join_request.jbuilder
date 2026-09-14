# frozen_string_literal: true

json.cache! ["v1", tour_join_request, tour_join_request.user, tour_join_request.decided_by] do
  json.partial!("api/v1/tour_join_requests/base", tour_join_request:)
end
