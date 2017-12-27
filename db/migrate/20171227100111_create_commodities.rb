class CreateCommodities < ActiveRecord::Migration[5.1]
  def change
    create_table :commodities, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
  end
end
