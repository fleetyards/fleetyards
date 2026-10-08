# frozen_string_literal: true

class AddProviderUidIndexToOmniauthConnections < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :omniauth_connections, %i[provider uid], algorithm: :concurrently
  end
end
