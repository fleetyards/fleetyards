# frozen_string_literal: true

# Left out entirely for anything not crafted, rather than rendered as null.
if blueprint.present?
  json.crafted do
    json.blueprint do
      json.id blueprint.id
      json.name blueprint.name
      json.slug blueprint.slug
    end
    json.qualities qualities || {}
  end
end
