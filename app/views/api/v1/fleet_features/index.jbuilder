# frozen_string_literal: true

json.array! @features do |feature|
  json.name feature[:name]
  json.enabled feature[:enabled]
  json.toggleable feature[:toggleable]
  json.groups feature[:groups]
end
