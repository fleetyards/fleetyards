# frozen_string_literal: true

json.array! @price_history do |day|
  json.recorded_on day[:recorded_on]
  json.sold_lowest day[:sold_lowest]
  json.sold_average day[:sold_average]
  json.sold_highest day[:sold_highest]
  json.bought_lowest day[:bought_lowest]
  json.bought_average day[:bought_average]
  json.bought_highest day[:bought_highest]
end
