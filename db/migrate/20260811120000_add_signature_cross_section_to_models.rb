class AddSignatureCrossSectionToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :signature_cross_section, :float
  end
end
