# frozen_string_literal: true

json.cache! ['v1', item] do
  json.partial! 'api/v1/progress_tracker_items/base', item: item
  json.model do
    if item.model.blank?
      json.null!
    else
      json.partial! 'api/v1/models/base', model: item.model
    end
  end
  json.partial! 'api/shared/dates', record: item
end
json.last_version do
  if item.versions.blank?
    json.null!
  else
    json.merge! item.versions.last.changeset
  end
end
