class AddHiddenFieldToModelLoaners < ActiveRecord::Migration[7.0]
  def change
    add_column :model_loaners, :hidden, :boolean, default: false
  end
end
