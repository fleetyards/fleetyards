class AddNotifiedToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :notified, :boolean, default: false
  end
end
