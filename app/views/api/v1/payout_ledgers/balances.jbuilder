# frozen_string_literal: true

json.total_income @settlement.total_income
json.total_expenses @settlement.total_expenses
json.profit @settlement.profit

json.balances do
  json.array! @settlement.balances do |balance|
    json.participant do
      json.partial! "api/v1/payout_participants/base", payout_participant: balance.participant
    end
    json.paid balance.paid
    json.held balance.held
    json.share balance.share
    json.net balance.net
  end
end

json.transfers do
  json.array! @settlement.transfers do |transfer|
    json.from do
      json.partial! "api/v1/payout_participants/base", payout_participant: transfer.from_participant
    end
    json.to do
      json.partial! "api/v1/payout_participants/base", payout_participant: transfer.to_participant
    end
    json.amount transfer.amount
  end
end
