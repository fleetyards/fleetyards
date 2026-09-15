# frozen_string_literal: true

module Patreon
  # `email` defaults so a client built without the campaigns.members[email]
  # scope still constructs -- the field is simply absent from the payload then,
  # which the importer reports as a scope problem rather than as no match.
  Member = Data.define(:id, :name, :status, :amount_cents, :pledged_at, :last_charge_date, :email) do
    def initialize(email: nil, **) = super
  end
end
