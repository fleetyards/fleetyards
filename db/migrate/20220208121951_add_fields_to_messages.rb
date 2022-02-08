class AddFieldsToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :read, :boolean, default: false
    add_column :messages, :archived, :boolean, default: false
    add_column :messages, :email, :string
    add_column :messages, :to, :text
    add_column :messages, :from_raw, :text
  end
end
