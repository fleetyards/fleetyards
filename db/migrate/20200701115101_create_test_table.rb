class CreateTestTable < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'

    create_table :test_tables, id: :uuid do |t|
      t.string :name
    end
  end
end
