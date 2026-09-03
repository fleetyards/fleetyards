# frozen_string_literal: true

json.id version.id

json.item_id version.item_id
json.item_type version.item_type
json.item_name @item_names&.dig([version.item_type, version.item_id])

json.event version.event
json.reason version.reason
json.reason_description version.reason_description

json.author do
  author = @authors[version.author_id]

  if author.present?
    json.id author.id
    json.username author.username
  else
    json.nil!
  end
end

json.changes do
  json.array!(version.changeset.sort) do |field, (from, to)|
    json.field field
    json.from from.to_s.presence
    json.to to.to_s.presence
  end
end

json.created_at version.created_at
