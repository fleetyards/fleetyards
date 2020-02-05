class CreateModelLoaners < ActiveRecord::Migration[6.0]
  def change
    create_table :model_loaners, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.uuid :model_id
      t.uuid :loaner_model_id

      t.timestamps
    end
  end
end
