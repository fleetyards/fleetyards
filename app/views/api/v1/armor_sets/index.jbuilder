# frozen_string_literal: true

json.cache! [*::DressingRoom::ArmorSets.cache_key, I18n.locale] do
  json.array! @armor_sets.all do |set|
    json.name set.name
    json.manufacturer_name set.manufacturer&.name
    json.item_type set.item_type
    json.item_type_label set.item_type_label
    if set.image_record
      json.image do
        json.partial! "api/v1/shared/file", record: set.image_record, attr: set.image_record.angled_image_attr
      end
    else
      json.image nil
    end
    json.pieces set.pieces do |piece|
      json.slot piece.slot
      json.slug piece.slug
      json.name piece.name
    end
  end
end
