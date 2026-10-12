# frozen_string_literal: true

json.id log_entry.id
json.title log_entry.title
json.body log_entry.body
json.logged_at log_entry.logged_at
json.public log_entry.public

json.partial! "api/shared/dates", record: log_entry
