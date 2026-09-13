# frozen_string_literal: true

# Withdrawing a request that was ignored.
#
# An ignored row is kept so that a further request from the same party is
# absorbed rather than delivered. That made withdrawing one observable: a real
# withdrawal destroys the row and it leaves the sender's outgoing list, while an
# ignored one stayed and reappeared on the next refetch -- which is exactly the
# tell the ignore exists to prevent.
#
# So a withdrawn-but-ignored row is marked rather than destroyed. It is hidden
# from the sender's lists, still absorbs, and a fresh request clears the mark so
# the row reads as pending again -- indistinguishable, at every step, from
# withdrawing and re-sending a request nobody ever ignored.
class AddWithdrawnAtToRelationships < ActiveRecord::Migration[8.1]
  def change
    add_column :friendships, :withdrawn_at, :datetime
    add_column :fleet_alliances, :withdrawn_at, :datetime
  end
end
