# frozen_string_literal: true

json.items do
  json.array! @inventory_transfers, partial: "api/v1/shared/inventory_transfer", as: :transfer
end
json.partial! "api/shared/meta", result: @inventory_transfers
