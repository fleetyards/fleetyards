# frozen_string_literal: true

json.code @result.code.to_s
json.items @result.items do |role|
  json.id role.id
  json.name role.name
end
