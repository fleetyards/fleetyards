# frozen_string_literal: true

json.items do
  json.array! @entries do |entry|
    record = entry.record

    json.id entry.id
    json.kind entry.kind
    json.category entry.category
    json.occurred_at entry.occurred_at
    json.involves_viewer entry.involves_viewer

    if entry.actor.present?
      json.actor do
        json.id entry.actor.id
        json.username entry.actor.username
        if entry.actor.avatar.attached?
          json.avatar do
            json.partial! "api/v1/shared/file", record: entry.actor, attr: :avatar
          end
        else
          json.avatar nil
        end
      end
    else
      json.actor nil
    end

    json.subject do
      case record
      when FleetMembership
        json.type "member"
        json.id record.id
        json.slug record.user.username
        json.title record.nickname.presence || record.user.username
      when FleetEvent
        json.type "event"
        json.id record.id
        json.slug record.slug
        json.title record.title
      when FleetContract
        json.type "contract"
        json.id record.id
        json.slug record.slug
        json.title record.title
      when InventoryTransfer
        json.type "inventory_transfer"
        json.id record.id
        json.slug nil
        json.title record.note
      when FleetInventoryItem
        json.type "inventory_item"
        json.id record.id
        json.slug nil
        json.title record.name
      end
    end

    if entry.inventory.present?
      json.inventory do
        json.id entry.inventory.id
        json.slug entry.inventory.slug
        json.name entry.inventory.name
      end
    else
      json.inventory nil
    end
  end
end
