# frozen_string_literal: true

# Whether the supporters page names this account's donations. Null until the
# supporter answers, which leaves each donation with the choice its platform
# reported -- Ko-fi asks the donor, Patreon is assumed anonymous.
class AddSupporterListedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :supporter_listed, :boolean
  end
end
