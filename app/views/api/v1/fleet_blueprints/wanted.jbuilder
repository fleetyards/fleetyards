# frozen_string_literal: true

json.items do
  json.array! @blueprints do |record|
    json.id record.id

    json.blueprint do
      json.partial! "api/v1/blueprints/blueprint", blueprint: record
    end

    wanters = @wanters.fetch(record.id, [])

    json.wanter_count wanters.size
    json.wanters wanters do |membership|
      json.partial! "api/v1/fleet_blueprints/member", membership:
    end
  end
end
json.partial! "api/shared/meta", result: @blueprints
