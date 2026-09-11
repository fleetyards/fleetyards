# frozen_string_literal: true

# Deliberately narrower than `_base`, which is the payload the admin imports
# channel broadcasts. `input` is the whole scraped pledge list and `importData`
# the whole uploaded file; neither is something the owner needs handed back, and
# a page of either would dwarf the rest of the list.
json.cache! ["v1-user", import, local_assigns.fetch(:extended, false)] do
  json.id import.id
  json.type import.type
  json.status import.aasm_state
  json.info import.info

  if import.hangar_group.present?
    json.hangar_group do
      json.partial! "api/v1/hangar_groups/base", group: import.hangar_group
    end
  end

  json.output import.output if local_assigns.fetch(:extended, false)

  json.started_at import.started_at
  json.finished_at import.finished_at
  json.failed_at import.failed_at
  json.cancelled_at import.cancelled_at

  json.partial! "api/shared/dates", record: import
end
