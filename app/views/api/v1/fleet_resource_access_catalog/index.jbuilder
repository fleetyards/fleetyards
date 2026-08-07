# frozen_string_literal: true

json.array! @groups do |group|
  json.key group[:key]
  json.privileges group[:privileges]
  json.manage_privilege group[:manage_privilege] if group[:manage_privilege]
end
