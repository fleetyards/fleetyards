# frozen_string_literal: true

class EnforceUniquePatreonIdentities < ActiveRecord::Migration[8.1]
  # A Patreon connection decides who a pledge belongs to, so two accounts
  # claiming the same one is not a duplicate row -- it is two people with a
  # claim on the same money, resolved arbitrarily by whichever the lookup
  # happened to return.
  #
  # Scoped to Patreon rather than made global: the other six providers only
  # decide who may sign in, they have years of rows behind them, and widening
  # the rule to all of them is a separate change with its own backfill.
  def change
    add_index :omniauth_connections, :uid,
      unique: true,
      where: "provider = #{OmniauthConnection.providers[:patreon]}",
      name: "index_omniauth_connections_on_patreon_uid"
  end
end
