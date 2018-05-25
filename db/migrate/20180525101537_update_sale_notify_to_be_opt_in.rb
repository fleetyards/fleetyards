class UpdateSaleNotifyToBeOptIn < ActiveRecord::Migration[5.2]
  def change
    change_column :vehicles, :sale_notify, :boolean, default: false
    change_column :users, :sale_notify, :boolean, default: false

    User.update_all(sale_notify: false)
    Vehicle.update_all(sale_notify: false)
  end
end
