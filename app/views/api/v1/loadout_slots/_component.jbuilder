# frozen_string_literal: true

json.id component.id
json.name component.name
json.slug component.slug
json.category component.category
json.type component.component_type
json.sub_type component.component_sub_type
json.size component.size
json.grade component.grade
json.grade_label component.grade_label
json.item_class component.item_class
json.item_class_label component.item_class_label
json.type_data component.type_data
json.craftable craftable_component_ids.include?(component.id)

# Only the small picture: a picker lists dozens of these, each needing no more.
if (image_attr = component.display_image_attr)
  file = component.public_send(image_attr)
  json.image_url(
    if file.representable?
      rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:small]))
    else
      rails_blob_url(file)
    end
  )
end
