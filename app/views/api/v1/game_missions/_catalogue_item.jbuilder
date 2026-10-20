# frozen_string_literal: true

if entry.catalogue_item.present?
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
