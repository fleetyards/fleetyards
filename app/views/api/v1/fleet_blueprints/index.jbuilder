# frozen_string_literal: true

json.items do
  json.array! @blueprints do |record|
    # The row's identity, which is the recipe's: a fleet holds at most one row
    # per blueprint however many members hold it.
    json.id record.id

    # Spelled out rather than `blueprint:` on its own: the shorthand reads the
    # *next* line as the value and swallows it.
    json.blueprint do
      json.partial! "api/v1/blueprints/blueprint", blueprint: record
    end

    owners = @owners.fetch(record.id, [])

    json.owner_count owners.size
    json.owners owners do |membership|
      json.partial! "api/v1/fleet_blueprints/member", membership:
    end
  end
end
json.partial! "api/shared/meta", result: @blueprints
