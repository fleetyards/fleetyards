# frozen_string_literal: true

json.id model.id
json.name model.name
json.slug model.slug
json.classification model.classification
json.classification_label model.classification&.humanize
json.production_status model.production_status

json.manufacturer do
  json.name model.manufacturer.name
  json.code model.manufacturer.code
  json.slug model.manufacturer.slug
end

json.metrics do
  json.length model.length.to_f
  json.beam model.beam.to_f
  json.height model.height.to_f
  json.fleetchart_offset_length (model.fleetchart_offset_length || model.length).to_f
  json.fleetchart_offset_beam (model.fleetchart_offset_beam || model.beam).to_f
  json.extended_length model.extended_length&.to_f
  json.extended_beam model.extended_beam&.to_f
  json.extended_fleetchart_offset_length model.extended_fleetchart_offset_length&.to_f
  json.extended_fleetchart_offset_beam model.extended_fleetchart_offset_beam&.to_f
  json.landed_length model.landed_length&.to_f
  json.landed_beam model.landed_beam&.to_f
  json.landed_fleetchart_offset_length model.landed_fleetchart_offset_length&.to_f
  json.landed_fleetchart_offset_beam model.landed_fleetchart_offset_beam&.to_f
end
