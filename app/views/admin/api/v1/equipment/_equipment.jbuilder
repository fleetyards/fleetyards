# frozen_string_literal: true

json.cache! ["v1", equipment] do
  json.partial!("admin/api/v1/equipment/base", equipment:)
end
