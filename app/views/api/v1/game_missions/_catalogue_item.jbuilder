# frozen_string_literal: true

# A component with no slug has no page to link to or card to fetch.
if entry.catalogue_item&.slug.present?
  json.catalogue_item do
    json.type entry.catalogue_item_type
    json.id entry.catalogue_item.id
    json.name entry.catalogue_item.name
    json.slug entry.catalogue_item.slug
    json.listed entry.catalogue_item.try(:listed?) != false
  end
else
  json.catalogue_item nil
end
