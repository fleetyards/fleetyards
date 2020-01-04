# frozen_string_literal: true

json.cache! ['v1', item] do
  json.partial! 'api/v1/roadmap/base', item: item
  json.model do
    if item.model.blank?
      json.null!
    else
      json.partial! 'api/v1/models/base', model: item.model
    end
  end
  json.last_version_changed_at item.last_version_changed_at(roadmap_query_params[:last_updated_at_lt]).iso8601
  json.last_version_changed_at_label I18n.l(item.last_version_changed_at(roadmap_query_params[:last_updated_at_lt]).utc, format: :label)
  json.last_version do
    if item.last_version(roadmap_query_params[:last_updated_at_lt]).nil?
      json.null!
    else
      json.merge! item.last_version(roadmap_query_params[:last_updated_at_lt]).changeset
    end
  end
  json.partial! 'api/shared/dates', record: item
end
