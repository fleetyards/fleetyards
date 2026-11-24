# frozen_string_literal: true

json.recorded @result.recorded
json.counts @result.counts

json.fields do
  json.array! @result.field_counts do |(field, count)|
    json.field field
    json.count count
  end
end

json.unrecorded do
  json.array! @result.unrecorded do |(field, count)|
    json.field field
    json.count count
  end
end

json.items do
  json.array! @entries do |entry|
    json.id entry.id
    json.kind entry.kind
    json.name entry.name
    json.slug @links[entry.id]
    json.context @contexts[entry.id]
    json.fields do
      json.array! entry.fields do |field|
        json.field field.field
        json.from field.from
        json.to field.to
        json.category field.category if field.category
      end
    end
  end
end

json.meta do
  json.pagination do
    json.total_count @entries.total_count
    json.current_page @entries.current_page
    json.total_pages @entries.total_pages
    json.per_page @entries.limit_value
    json.default_per_page Api::V1::ScDataController::DIFF_PER_PAGE
    json.max_per_page Api::V1::ScDataController::DIFF_PER_PAGE_MAX
    json.per_page_steps PageSizes::STEPS
  end
end
