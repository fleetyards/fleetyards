# frozen_string_literal: true

# The month is part of the key because supporter status is a fact about the
# current one: a one-off stops counting when the month turns over, and nothing
# touches the user record to say so. The public profile keys the same way.
json.cache! ["v1", user, Date.current.beginning_of_month] do
  json.partial!("admin/api/v1/users/base", user:)
end
