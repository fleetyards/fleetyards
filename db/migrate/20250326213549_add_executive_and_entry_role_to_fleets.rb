class AddExecutiveAndEntryRoleToFleets < ActiveRecord::Migration[7.2]
  def change
    add_reference :fleets, :executive_role, type: :uuid
    add_reference :fleets, :entry_role, type: :uuid
  end
end
