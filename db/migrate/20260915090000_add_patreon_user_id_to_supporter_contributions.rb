# frozen_string_literal: true

class AddPatreonUserIdToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    # The Patreon account behind the membership, not the membership itself --
    # patreon_member_id is per campaign, this is per person, and it is what an
    # OAuth connection's uid matches.
    #
    # Not unique: one account can hold more than one membership over time, and
    # each ended pledge keeps its own row.
    add_column :supporter_contributions, :patreon_user_id, :string
    add_index :supporter_contributions, :patreon_user_id, where: "patreon_user_id IS NOT NULL"
  end
end
