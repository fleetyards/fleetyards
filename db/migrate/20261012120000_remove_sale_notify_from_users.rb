# frozen_string_literal: true

# The `model_on_sale` notification preference replaced it. The release before
# this one stopped selecting it (`ignored_columns`), so the containers still
# serving it are unaffected by the pre-deploy migration.
class RemoveSaleNotifyFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :sale_notify, :boolean, default: false
  end
end
