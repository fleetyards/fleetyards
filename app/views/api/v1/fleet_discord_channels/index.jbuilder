# frozen_string_literal: true

json.code @result.code.to_s
json.items @result.channels do |channel|
  json.id channel.id
  json.name channel.name
  json.parent_name channel.parent_name
end
