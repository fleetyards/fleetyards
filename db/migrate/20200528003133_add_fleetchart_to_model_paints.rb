# frozen_string_literal: true

class AddFleetchartToModelPaints < ActiveRecord::Migration[6.0]
  def change
    add_column :model_paints, :fleetchart_image, :string
  end
end
