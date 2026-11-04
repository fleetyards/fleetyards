# frozen_string_literal: true

json.id model.id
json.name model.name
json.slug model.slug
json.manufacturer_name model.manufacturer&.name
json.manufacturer_icon((model.manufacturer&.icon&.attached? && rails_blob_url(model.manufacturer.icon)) || nil)
json.classification model.classification
json.size model.size
json.production_status model.production_status
json.pledge_price model.pledge_price&.to_f
json.on_sale model.on_sale || false
json.ccu_into model.ccu_target_status
json.ccu_out_of model.ccu_source_status
json.ccu_into_from model.ccu_into_from_ids
json.crew model.crew
json.cargo model.cargo&.to_f

image_attr = Model::IMAGE_ATTACHMENT_NAMES.find { |attr| model.public_send(attr).attached? }
if image_attr
  json.image do
    json.partial! "api/v1/shared/file", record: model, attr: image_attr
  end
end
