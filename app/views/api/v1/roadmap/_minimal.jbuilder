# frozen_string_literal: true

json.cache! ["v1", item] do
  json.partial!("api/v1/roadmap/base", item:)
  json.model do
    json.partial! "api/v1/models/minimal", model: item.model if item.model.present?
  end
  json.partial! "api/shared/dates", record: item
end
json.last_version_changed_at item.last_version_changed_at(roadmap_query_params[:last_updated_at_lt]).iso8601
json.last_version_changed_at_label I18n.l(item.last_version_changed_at(roadmap_query_params[:last_updated_at_lt]).utc, format: :label)
if item.last_version(roadmap_query_params[:last_updated_at_lt]).present?
  json.last_version item.last_version(roadmap_query_params[:last_updated_at_lt]).changeset
end
