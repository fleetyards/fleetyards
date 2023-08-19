# frozen_string_literal: true

json.cache! ["v1", result] do
  json.partial!("api/v1/search/base", result:)
end
