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
