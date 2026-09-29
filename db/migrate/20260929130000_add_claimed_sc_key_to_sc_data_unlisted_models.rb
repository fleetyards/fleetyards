# frozen_string_literal: true

class AddClaimedScKeyToScDataUnlistedModels < ActiveRecord::Migration[8.1]
  def change
    add_column :sc_data_unlisted_models, :claimed_sc_key, :boolean, default: false, null: false
  end
end
