# frozen_string_literal: true

json.name manufacturer.name
json.slug manufacturer.slug
json.logo manufacturer.logo.small.url if manufacturer.logo.present?
