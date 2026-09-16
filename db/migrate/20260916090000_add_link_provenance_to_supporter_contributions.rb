# frozen_string_literal: true

class AddLinkProvenanceToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    # The key the donor supplied, kept apart from the free-text note so an admin
    # entering a hand-received payment has a field to put it in rather than a
    # convention to remember.
    #
    # Stored even when it matches nobody: a donation often arrives before its
    # donor registers, and the later re-run of the linker has nowhere else to
    # read the key from.
    add_column :supporter_contributions, :claim_key, :string

    # Which rule produced the link, so a linked row says where it came from.
    # Null for an unlinked one -- there is no rule to name.
    add_column :supporter_contributions, :linked_via, :string
    add_index :supporter_contributions, :linked_via, where: "linked_via IS NOT NULL"
  end
end
