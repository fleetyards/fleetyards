# frozen_string_literal: true

module Patreon
  Member = Data.define(:id, :name, :status, :amount_cents, :pledged_at, :last_charge_date)
end
