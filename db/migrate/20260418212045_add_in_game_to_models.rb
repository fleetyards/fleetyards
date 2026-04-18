class AddInGameToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :in_game, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        sc_environment = Rails.configuration.sc_data[:environment]
        Model.find_each do |model|
          identifier = model.slug&.tr('-', '_')
          next if identifier.blank?

          file_exists = File.exist?(Rails.root.join("data/sc_data/parsed/#{sc_environment}/models/#{identifier}.json"))
          model.update_columns(in_game: true, production_status: 'flight-ready') if file_exists
        end
      end
    end
  end
end
