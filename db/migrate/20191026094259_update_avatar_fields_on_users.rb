class UpdateAvatarFieldsOnUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :avatar, :string

    remove_column :users, :gravatar, :string
    remove_column :users, :gravatar_hash, :string
  end
end
