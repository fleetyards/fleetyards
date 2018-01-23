# frozen_string_literal: true

json.cache! ['v1', @fleet] do
  json.partial! 'api/v1/fleets/complete', fleet: @fleet
end
