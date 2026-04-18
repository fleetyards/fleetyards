class RemoveScIdentifierFromModelsAndComponents < ActiveRecord::Migration[8.1]
  def change
    remove_column :models, :sc_identifier, :string
    remove_column :components, :sc_identifier, :string
  end
end
