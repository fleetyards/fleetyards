class ChangeSignatureCrossSectionToJsonb < ActiveRecord::Migration[8.1]
  def up
    remove_column :models, :signature_cross_section
    add_column :models, :signature_cross_section, :jsonb
  end

  def down
    remove_column :models, :signature_cross_section
    add_column :models, :signature_cross_section, :float
  end
end
