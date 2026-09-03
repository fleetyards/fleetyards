# frozen_string_literal: true

json.array! @price_history do |point|
  json.changed_at point[:changed_at]
  json.from point[:from]
  json.to point[:to]
end
