# frozen_string_literal: true

# The importer only links a module to the game files when it creates one, and
# the Galaxy's were created before it knew their keys. The next sc_data load
# fills them in from the key.
class LinkGalaxyModulesToGameData < ActiveRecord::Migration[8.1]
  SC_KEYS = {
    "Cargo Module" => "RSI_Galaxy_Module_Cargo",
    "Med Bay Module" => "RSI_Galaxy_Module_Medical"
  }.freeze

  def up
    galaxy = ::Model.find_by(slug: "rsi-galaxy")
    return if galaxy.nil?

    SC_KEYS.each do |name, sc_key|
      galaxy.modules.where(name: name, sc_key: nil).update_all(sc_key: sc_key, updated_at: Time.current)
    end
  end

  def down
  end
end
