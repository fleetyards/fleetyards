# frozen_string_literal: true

json.array! @features do |feature|
  json.name feature[:name]
  json.enabled feature[:enabled]
  json.enabled_for_self feature[:enabled_for_self]
  json.scope feature[:scope]
  json.toggleable feature[:toggleable]
  json.fleets feature[:fleets] do |fleet|
    json.name fleet[:name]
    json.slug fleet[:slug]
  end
  json.groups feature[:groups]
end
