# frozen_string_literal: true

json.array! @features do |feature|
  json.name feature[:name]
  json.enabled feature[:enabled]
end
