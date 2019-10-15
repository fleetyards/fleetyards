class TransformFleetSids < ActiveRecord::Migration[5.2]
  def up
    Fleet.find_each do |fleet|
      fleet.update(sid: fleet.sid.upcase)
    end
  end

  def down
  end
end
