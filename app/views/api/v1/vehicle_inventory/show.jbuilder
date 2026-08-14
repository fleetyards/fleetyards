# frozen_string_literal: true

# Deliberately uncached: an unprovisioned inventory has no cache key of its own.
json.partial! "api/v1/shared/inventory", inventory: @inventory
