# frozen_string_literal: true

json.environment @environment
json.version @version
json.from_version @from_version if @from_version.present?
json.total_count @total_count

json.items do
  json.array! @items do |item|
    model = item[:model]

    json.model do
      json.id model.id
      json.name model.name
      json.slug model.slug
      json.manufacturer_name model.manufacturer.name if model.manufacturer.present?

      if model.display_image_attr
        json.store_image do
          json.partial! "api/v1/shared/file", record: model, attr: model.display_image_attr
        end
      end
    end

    json.owned_count item[:owned_count]
    json.wanted item[:wanted]
    json.change_count item[:changes].size

    json.changes do
      json.array! item[:changes] do |change|
        json.id change.id
        json.environment change.environment
        json.from_version change.from_version
        json.to_version change.to_version
        json.field change.field
        json.old_value change.old_value
        json.new_value change.new_value
        json.recorded_at change.recorded_at
      end
    end
  end
end
