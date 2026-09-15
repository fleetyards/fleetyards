# frozen_string_literal: true

module Patreon
  # `email` and `patreon_user_id` default so a client built without the
  # campaigns.members[email] scope, or a payload without the user relationship,
  # still constructs -- the fields are simply absent then, which the importer
  # reports rather than failing on.
  Member = Data.define(:id, :name, :status, :amount_cents, :pledged_at,
    :last_charge_date, :email, :patreon_user_id) do
    def initialize(email: nil, patreon_user_id: nil, **) = super
  end
end
