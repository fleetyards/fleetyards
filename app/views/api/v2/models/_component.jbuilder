# frozen_string_literal: true

json.id component.id
json.name component.name
json.slug component.slug
json.grade component.grade
json.size component.size
json.type component.item_type
json.type_label component.item_type_label
json.item_class component.item_class
json.item_class_label component.item_class_label
json.description component.description
json.type_data component.type_data
json.manufacturer do
  json.null! if component.manufacturer.blank?
  json.partial! 'api/v1/manufacturers/base', manufacturer: component.manufacturer if component.manufacturer.present?
end
