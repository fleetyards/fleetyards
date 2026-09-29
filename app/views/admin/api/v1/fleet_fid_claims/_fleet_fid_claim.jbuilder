# frozen_string_literal: true

json.ignore_nil! false

json.id claim.id
json.fid claim.fid
json.state claim.state
json.cancel_reason claim.cancel_reason
json.ends_at claim.ends_at.utc.iso8601
json.claimant_id claim.claimant_id
json.claimant_name claim.claimant.name
json.claimant_fid claim.claimant.fid
json.holder_id claim.holder_id
json.holder_name claim.holder&.name
json.holder_fid claim.holder&.fid
json.holder_new_fid claim.holder_new_fid
json.completed_at claim.completed_at&.utc&.iso8601
json.cancelled_at claim.cancelled_at&.utc&.iso8601
json.created_at claim.created_at.utc.iso8601
