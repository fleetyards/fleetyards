# frozen_string_literal: true

json.cache! ["v2", equipment] do
  json.partial!("api/v2/equipment/base", equipment:)
  json.partial! "api/shared/dates", record: equipment
end
