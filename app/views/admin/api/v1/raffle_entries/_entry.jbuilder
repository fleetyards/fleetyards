# frozen_string_literal: true

json.id entry.id
json.username entry.display_username
json.account_deleted entry.user_id.nil?
json.masked_email entry.masked_email if entry.recipient_email.present?
json.conditions_accepted_at entry.conditions_accepted_at.utc.iso8601
json.conditions_version entry.conditions_version
json.draw_position entry.draw_position if entry.draw_position.present?
json.won_at entry.won_at.utc.iso8601 if entry.won_at.present?
json.claim_deadline_at entry.claim_deadline_at.utc.iso8601 if entry.claim_deadline_at.present?
json.claimed_at entry.claimed_at.utc.iso8601 if entry.claimed_at.present?
json.forfeited_at entry.forfeited_at.utc.iso8601 if entry.forfeited_at.present?
json.claim_mail_status entry.claim_mail_status if entry.claim_mail_status.present?
json.prize_mail_status entry.prize_mail_status if entry.prize_mail_status.present?
json.prize_mail_sent_at entry.prize_mail_sent_at.utc.iso8601 if entry.prize_mail_sent_at.present?
json.claimable entry.claimable?
if (warnings = local_assigns[:warnings]&.for(entry))
  json.shared_ip_with warnings.shared_ip_with
  json.same_inbox_as warnings.same_inbox_as
  json.new_account warnings.new_account
  json.placeholder_email warnings.placeholder_email
end
json.created_at entry.created_at.utc.iso8601
