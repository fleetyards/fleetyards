# frozen_string_literal: true

json.items do
  json.array! @blueprints do |record|
    # Spelled out rather than `blueprint:` on its own: the shorthand reads the
    # *next* line as the value and swallows it.
    json.blueprint do
      json.partial! "api/v1/blueprints/blueprint", blueprint: record
    end

    owners = @owners.fetch(record.id, [])

    json.owner_count owners.size
    json.owners owners do |membership|
      json.user_id membership.user_id
      json.username membership.user.username
      json.nickname membership.nickname
      json.avatar do
        json.partial! "api/v1/shared/file", record: membership.user, attr: :avatar
      end
    end
  end
end
json.partial! "api/shared/meta", result: @blueprints
