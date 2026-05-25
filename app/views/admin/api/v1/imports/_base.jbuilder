# frozen_string_literal: true

json.id import.id
json.type import.type
json.status import.aasm_state
json.info import.info
json.version import.version
json.input import.input

if import.respond_to?(:admin_user) && import.admin_user.present?
  json.admin_user do
    json.id import.admin_user.id
    json.username import.admin_user.username
  end
end

if import.respond_to?(:user) && import.user.present?
  json.user do
    json.id import.user.id
    json.username import.user.username
  end
end

if local_assigns.fetch(:extended, false)
  json.output import.output
  if import.is_a?(Imports::HangarImport) && import.import.attached?
    json.import rails_blob_url(import.import)
  end
  json.import_data import.import_data
end

json.started_at import.started_at
json.finished_at import.finished_at
json.failed_at import.failed_at

json.partial! "api/shared/dates", record: import
