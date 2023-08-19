# frozen_string_literal: true

json.cache! ["v1", user] do
  json.partial!("api/v1/users/base_public", user:)
end
