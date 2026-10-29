# frozen_string_literal: true

class AddSubTypesToHardpoints < ActiveRecord::Migration[8.1]
  def change
    add_column :hardpoints, :sub_types, :string
    add_column :hardpoint_builds, :sub_types, :string
  end
end
