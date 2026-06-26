# frozen_string_literal: true

json.items do
  if @discarded_fleets
    json.array! @discarded_fleets do |fleet|
      json.id fleet.id
      json.fid fleet.fid
      json.name fleet.name
      json.slug fleet.slug
      json.public_fleet fleet.public_fleet
      json.description fleet.description if fleet.description.present?
      json.created_by fleet.created_by if fleet.created_by.present?
      json.source "discarded"
      json.destroyed_at fleet.discarded_at

      destroyed_by = @destroyed_by[@discarded_by[fleet.id]]
      json.destroyed_by destroyed_by if destroyed_by.present?

      json.restorable true
    end
  else
    json.array! @purged_fleets do |version|
      object = version.object || {}
      json.id version.item_id
      json.fid object["fid"]
      json.name object["name"]
      json.slug object["slug"]
      json.public_fleet object["public_fleet"] || false
      json.description object["description"] if object["description"].present?
      json.created_by object["created_by"] if object["created_by"].present?
      json.source "purged"
      json.destroyed_at version.created_at

      destroyed_by = @destroyed_by[version.whodunnit]
      json.destroyed_by destroyed_by if destroyed_by.present?

      json.restorable true
    end
  end
end

json.partial! "api/shared/meta", result: (@discarded_fleets || @purged_fleets)
