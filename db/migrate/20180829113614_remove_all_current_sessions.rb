class RemoveAllCurrentSessions < ActiveRecord::Migration[5.2]
  def up
    AuthToken.destroy_all
  end

  def down
  end
end
