# frozen_string_literal: true

json.items do
  json.array! @buyback_pledges, partial: "api/v1/hangar_buybacks/buyback_pledge", as: :buyback_pledge
end
json.partial! "api/shared/meta", result: @buyback_pledges
