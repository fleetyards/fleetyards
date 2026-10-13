# frozen_string_literal: true

class RemoveSaleNotifyFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :sale_notify, :boolean, default: false
  end
end
