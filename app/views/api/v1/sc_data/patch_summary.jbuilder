# frozen_string_literal: true

json.from @summary[:from]
json.to @summary[:to]
json.counts @summary[:counts]

json.new_ships @new_ships, partial: "api/v1/sc_data/ship", as: :model
json.latest_arrivals @latest_arrivals, partial: "api/v1/sc_data/ship", as: :model
json.latest_arrivals_version @latest_arrivals_version

json.ship_changes @ship_changes do |change|
  json.model do
    json.partial! "api/v1/sc_data/ship", model: change[:model]
  end
  json.fields change[:fields]
end

json.item_changes @item_changes do |change|
  json.kind change[:kind]
  json.id change[:id]
  json.name change[:name]
  json.slug change[:slug]
  json.fields change[:fields]
end
