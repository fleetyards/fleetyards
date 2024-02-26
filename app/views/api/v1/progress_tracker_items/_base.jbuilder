# frozen_string_literal: true

json.id item.id
json.title item.title
json.team item.team
json.description item.description
json.start_date item.start_date
json.start_date_label I18n.l(item.start_date, format: :label)
json.end_date item.end_date
json.end_date_label I18n.l(item.end_date, format: :label)
json.status item.status
json.status_label item.status_label

json.model do
  if item.model.blank?
    json.null!
  else
    json.partial! "api/v1/models/base", model: item.model
  end
end
json.partial! "api/shared/dates", record: item
