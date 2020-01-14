class PrefillFleetNames < ActiveRecord::Migration[5.2]
  def up
    Fleet.find_each do |fleet|
      fleet.update(name: fleet.fid)
    end
  end

  def down
  end
end
