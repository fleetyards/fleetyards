# frozen_string_literal: true

json.items do
  json.array! @claims do |claim|
    json.partial! "admin/api/v1/fleet_fid_claims/fleet_fid_claim", claim:
  end
end

json.partial! "api/shared/meta", result: @claims
