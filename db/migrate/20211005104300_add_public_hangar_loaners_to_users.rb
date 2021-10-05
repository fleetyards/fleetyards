class AddPublicHangarLoanersToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :public_hangar_loaners, :boolean, default: false
  end
end
