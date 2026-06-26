# frozen_string_literal: true

json.items do
  if @discarded_fleets
    json.array! @discarded_fleets do |fleet|
      json.id fleet.id
      json.fid fleet.fid
      json.name fleet.name
      json.slug fleet.slug
      json.description fleet.description
      json.public_fleet fleet.public_fleet
      json.created_by fleet.created_by
      json.source "discarded"
      json.destroyed_at fleet.discarded_at
      json.destroyed_by fleet.versions.reorder(created_at: :desc).first&.whodunnit
      json.restorable true
    end
  else
    json.array! @purged_fleets do |version|
      object = version.object || {}
      json.id version.item_id
      json.fid object["fid"]
      json.name object["name"]
      json.slug object["slug"]
      json.description object["description"]
      json.public_fleet object["public_fleet"]
      json.created_by object["created_by"]
      json.source "purged"
      json.destroyed_at version.created_at
      json.destroyed_by version.whodunnit
      json.restorable true
    end
  end
end

json.partial! "api/shared/meta", result: (@discarded_fleets || @purged_fleets)
