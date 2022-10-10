class PrefillHangarUpdatedAtInUsers < ActiveRecord::Migration[6.1]
  def up
    User.find_each do |user|
      last_updated_vehicle = user.vehicles.where(loaner: false).order(updated_at: :desc).first

      if last_updated_vehicle.present?
        user.update(hangar_updated_at: last_updated_vehicle.updated_at)
      else
        user.update(hangar_updated_at: user.updated_at)
      end
    end
  end

  def down
  end
end
