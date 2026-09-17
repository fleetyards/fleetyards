# frozen_string_literal: true

# The fleet a person's donations support, chosen independently of any donation.
#
# Without it the only way to say which fleet money is for is on a contribution,
# which does not exist until a payment has been imported and matched -- days,
# for a Patreon sync or a hand-entered PayPal payment. So the one moment
# somebody is thinking about it, just before donating, is the one moment they
# cannot answer it.
#
# The contribution keeps the authoritative per-donation answer; this is the
# default the linker stamps onto it, and an override on the contribution still
# works for somebody splitting across two fleets.
class AddSupportedFleetToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :supported_fleet,
      type: :uuid,
      null: true,
      index: {where: "supported_fleet_id IS NOT NULL"},
      # Nullify rather than restrict: a fleet being deleted must not block the
      # deletion. `User#check_fleet_memberships` destroys a fleet whose sole
      # admin is closing their account, and a restricting reference from that
      # same account's row would abort the whole thing.
      foreign_key: {to_table: :fleets, on_delete: :nullify}
  end
end
