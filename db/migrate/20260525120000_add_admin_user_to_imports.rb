# frozen_string_literal: true

class AddAdminUserToImports < ActiveRecord::Migration[8.1]
  def change
    add_reference :imports, :admin_user, type: :uuid, foreign_key: true, null: true
  end
end
