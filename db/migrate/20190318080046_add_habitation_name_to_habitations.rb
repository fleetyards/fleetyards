class AddHabitationNameToHabitations < ActiveRecord::Migration[5.2]
  def change
    add_column :habitations, :habitation_name, :string
  end
end
