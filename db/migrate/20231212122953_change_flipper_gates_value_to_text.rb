class ChangeFlipperGatesValueToText < ActiveRecord::Migration[7.1]
  def up
    change_column :flipper_gates, :value, :text
  end

  def down
    change_column :flipper_gates, :value, :string
  end
end
