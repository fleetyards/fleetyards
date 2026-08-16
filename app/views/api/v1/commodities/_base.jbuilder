# frozen_string_literal: true

json.id commodity.id
json.name commodity.name
json.slug commodity.slug
json.commodity_type commodity.commodity_type
json.description commodity.description

json.partial! "api/shared/dates", record: commodity
