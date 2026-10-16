# frozen_string_literal: true

class AddMedicalBedsToModelModules < ActiveRecord::Migration[8.1]
  def change
    add_column :model_modules, :medical_beds, :string
    add_column :model_module_builds, :medical_beds, :string
  end
end
