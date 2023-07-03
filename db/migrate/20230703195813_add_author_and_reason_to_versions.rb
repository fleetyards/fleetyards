class AddAuthorAndReasonToVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :author_id, :uuid
    add_column :versions, :reason, :string
    add_column :versions, :reason_description, :text
  end
end
