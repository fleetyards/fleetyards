class PrefillFallbackFieldsInModels < ActiveRecord::Migration[5.1]
  def up
    Model.find_each do |model|
      model.update(
        fallback_height: model.addition_height,
        fallback_beam: model.addition_beam,
        fallback_length: model.addition_length,
        fallback_mass: model.addition_mass,
        fallback_cargo: model.addition_cargo,
        fallback_min_crew: model.addition_min_crew,
        fallback_price: model.addition_price,
        fallback_max_crew: model.addition_max_crew,
        fallback_scm_speed: model.addition_scm_speed,
        fallback_afterburner_speed: model.addition_afterburner_speed
      )
    end
  end

  def down
  end
end
