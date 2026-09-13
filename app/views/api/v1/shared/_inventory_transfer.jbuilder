# frozen_string_literal: true

json.id transfer.id
json.state transfer.aasm_state
json.note transfer.note
json.immediate transfer.immediate?

# Both ends render through the same partial whichever of the two schemas they
# are in -- an inventory is an inventory to a reader.
json.source do
  json.partial! "api/v1/shared/inventory_transfer_endpoint", inventory: transfer.source
end

json.destination do
  json.partial! "api/v1/shared/inventory_transfer_endpoint", inventory: transfer.destination
end

json.sender do
  json.partial! "api/v1/shared/transfer_party", party: transfer.sender_party
end

json.recipient do
  json.partial! "api/v1/shared/transfer_party", party: transfer.recipient_party
end

# Who holds the destination, which is not the same question as who it was
# addressed to: an immediate transfer names no recipient at all, and a delivered
# one is more usefully described by whose inventory it reached. Null until there
# is a destination.
json.destination_party do
  json.partial! "api/v1/shared/transfer_party",
    party: ::InventoryTransfer.party_of(transfer.destination)
end

json.initiated_by transfer.initiated_by&.username
json.resolved_by transfer.resolved_by&.username

# The shipment. These are ledger entries rather than rows of a line table, so
# what is listed here is exactly what left the source.
json.lines do
  json.array! transfer.dispatched_entries do |entry|
    json.id entry.id
    json.name entry.name
    json.category entry.category
    json.unit entry.unit
    json.quantity entry.quantity.to_f
    json.quality entry.quality
    json.position_id entry.position_id
    json.item_available entry.item_available?

    if entry.display_image.present?
      json.image do
        json.partial! "api/v1/shared/file", record: entry, attr: :image
      end
    else
      json.image nil
    end
  end
end

json.expires_at transfer.expires_at
json.completed_at transfer.completed_at
json.declined_at transfer.declined_at
json.cancelled_at transfer.cancelled_at
json.expired_at transfer.expired_at

json.partial! "api/shared/dates", record: transfer
