# frozen_string_literal: true

json.name HTMLEntities.new.decode(manufacturer.name)
json.long_name HTMLEntities.new.decode(manufacturer.long_name || manufacturer.name)
json.slug manufacturer.slug
json.code manufacturer.code
json.logo((manufacturer.logo.small.url if manufacturer.logo.present?))
