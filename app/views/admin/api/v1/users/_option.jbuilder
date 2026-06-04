# frozen_string_literal: true

json.cache! ["admin/v1/users/option", user] do
  json.id user.id
  json.username user.username
end
