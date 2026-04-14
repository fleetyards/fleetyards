class CreateRaptorModel < ActiveRecord::Migration[8.1]
  def up
    manufacturer = Manufacturer.find_by(code: "MISC") || Manufacturer.find_by!(name: "Musashi Industrial & Starflight Concern")

    Model.find_or_create_by!(name: "Raptor") do |model|
      model.manufacturer = manufacturer
      model.hidden = true
    end
  end

  def down
    Model.find_by(name: "Raptor")&.destroy
  end
end
