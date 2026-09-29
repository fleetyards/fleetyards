# frozen_string_literal: true

json.cache! ["v2", user, Date.current.beginning_of_month] do
  json.partial!("api/v1/public/users/base", user:)
end
