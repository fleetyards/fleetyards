# frozen_string_literal: true

class AddDateFormatToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :date_format, :string, default: "dmy_dots", null: false
  end
end
