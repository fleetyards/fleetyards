# frozen_string_literal: true

class AddApprovalToOauthApplications < ActiveRecord::Migration[8.1]
  def up
    add_column :oauth_applications, :aasm_state, :string, null: false, default: "pending"
    add_column :oauth_applications, :approved_at, :datetime
    add_column :oauth_applications, :rejected_at, :datetime
    add_column :oauth_applications, :rejection_reason, :text
    add_column :oauth_applications, :reviewed_by_id, :uuid

    add_index :oauth_applications, :aasm_state
    add_index :oauth_applications, :reviewed_by_id

    # Everything that exists predates the gate and was created by an operator,
    # so it keeps working. `approved_at` stays null: nobody approved these, and
    # a fabricated timestamp would claim a review that never happened.
    up_only do
      execute("UPDATE oauth_applications SET aasm_state = 'approved'")
    end
  end

  def down
    remove_index :oauth_applications, :reviewed_by_id
    remove_index :oauth_applications, :aasm_state

    remove_column :oauth_applications, :reviewed_by_id
    remove_column :oauth_applications, :rejection_reason
    remove_column :oauth_applications, :rejected_at
    remove_column :oauth_applications, :approved_at
    remove_column :oauth_applications, :aasm_state
  end
end
