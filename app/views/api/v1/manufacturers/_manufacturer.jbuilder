# frozen_string_literal: true

json.cache! ["v2", manufacturer] do
  json.partial!("api/v1/manufacturers/base", manufacturer:)
end
