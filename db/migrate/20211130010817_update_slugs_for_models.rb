class UpdateSlugsForModels < ActiveRecord::Migration[6.1]
  def up
    Model.find_each do |model|
      model.save
    end
  end

  def down
  end
end
