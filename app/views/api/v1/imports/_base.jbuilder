# frozen_string_literal: true

json.id import.id
json.type import.type
json.status import.aasm_state
json.info import.info
json.version import.version

if local_assigns.fetch(:extended, false)
  json.input import.input
  json.output import.output
  json.import import.import
  json.import_data import.import_data
end

json.started_at import.started_at
json.finished_at import.finished_at
json.failed_at import.failed_at

json.partial! "api/shared/dates", record: import
