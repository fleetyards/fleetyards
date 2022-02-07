class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.string :from
      t.uuid :user_id
      t.string :subject
      t.text :body

      t.timestamps
    end
  end
end
