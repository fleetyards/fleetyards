# frozen_string_literal: true

json.cache! ["v1", dock] do
  json.partial!("admin/api/v1/docks/base", dock:)
end
