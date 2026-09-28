# frozen_string_literal: true

json.cache! ["v2", fleet] do
  json.partial!("admin/api/v1/fleets/base", fleet:)
end
