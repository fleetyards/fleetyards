# frozen_string_literal: true

json.id manufacturer.id
json.name manufacturer.name
json.long_name manufacturer.long_name || manufacturer.name
json.slug manufacturer.slug
json.code manufacturer.code
json.logo((manufacturer.logo.small.url if manufacturer.logo.present?))

json.partial! "api/shared/dates", record: manufacturer
