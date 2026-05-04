class AddBengalCarrier < ActiveRecord::Migration[8.1]
  def up
    rsi = Manufacturer.find_by(slug: "roberts-space-industries")
    return if rsi.blank?
    return if Model.exists?(slug: "rsi-bengal")

    Model.create!(
      name: "Bengal",
      slug: "rsi-bengal",
      manufacturer: rsi,
      classification: "combat",
      focus: "Carrier",
      size: "capital",
      length: 1000.0,
      beam: 287.0,
      height: 190.0,
      sc_key: "rsi_bengal_pu_ai_uee_fleetweek_2021",
      in_game: true,
      production_status: "flight-ready",
      player_ownable: false,
      hidden: false,
      active: true
    )
  end

  def down
    Model.where(slug: "rsi-bengal").find_each do |model|
      # model_positions reference hardpoints via FK; destroy them first so
      # the dependent: :destroy cascade on hardpoints doesn't trip the FK.
      model.model_positions.destroy_all
      model.destroy!
    end
  end
end
