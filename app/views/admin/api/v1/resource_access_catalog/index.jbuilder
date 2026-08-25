# frozen_string_literal: true

json.array! @groups do |group|
  json.key group[:key]
  json.privileges group[:privileges]
end
