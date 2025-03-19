class AddNormalizedFidToFleets < ActiveRecord::Migration[7.2]
  def change
    add_column :fleets, :normalized_fid, :string

    Fleet.find_each do |fleet|
      fleet.update!(normalized_fid: fleet.fid.downcase)
    rescue ActiveRecord::RecordInvalid => e
      puts fleet.id
      puts e.message
    end
  end
end
