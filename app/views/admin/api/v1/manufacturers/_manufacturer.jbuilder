# frozen_string_literal: true

json.cache! ["v1", manufacturer] do
  json.partial!("admin/api/v1/manufacturers/base", manufacturer:)
end
