# frozen_string_literal: true

class AddPatreonFieldsToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    add_column :supporter_contributions, :source, :string, null: false, default: "manual"
    add_column :supporter_contributions, :patreon_member_id, :string
    add_column :supporter_contributions, :source_amount_cents, :integer
    add_column :supporter_contributions, :source_currency, :string

    add_index :supporter_contributions, :patreon_member_id,
      unique: true,
      where: "patreon_member_id IS NOT NULL"
  end
end
