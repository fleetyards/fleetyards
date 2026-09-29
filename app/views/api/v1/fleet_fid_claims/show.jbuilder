# frozen_string_literal: true

json.ignore_nil! false

json.availability FleetFidClaim.availability_for(@fleet)
json.fid @fleet.rsi_verified? ? @fleet.rsi_verified_sid : nil

outgoing = @fleet.outgoing_fid_claims.open.includes(:claimant, :holder).first
# Only while the fleet still holds the FID: one that renamed itself away has
# nothing left to lose to the claim.
incoming = @fleet.incoming_fid_claims.open.includes(:claimant, :holder).find_by(fid: @fleet.fid.upcase)

if outgoing.present?
  json.outgoing do
    json.partial! "api/v1/fleet_fid_claims/fleet_fid_claim", claim: outgoing
  end
end

if incoming.present?
  json.incoming do
    json.partial! "api/v1/fleet_fid_claims/fleet_fid_claim", claim: incoming
  end
end
