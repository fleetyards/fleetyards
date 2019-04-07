class CleanupFleets < ActiveRecord::Migration[5.2]
  def up
    Fleet.find_each do |fleet|
      fleet.sid = fleet.sid.strip.downcase
      fleet.save
    end
  end

  def down
  end
end
