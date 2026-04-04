# frozen_string_literal: true

class RemoveCarrierwaveColumns < ActiveRecord::Migration[8.0]
  def change
    # Models — 13 string columns + 22 width/height columns
    change_table :models, bulk: true do |t|
      t.remove :store_image, type: :string
      t.remove :rsi_store_image, type: :string
      t.remove :fleetchart_image, type: :string
      t.remove :top_view, type: :string
      t.remove :side_view, type: :string
      t.remove :front_view, type: :string
      t.remove :angled_view, type: :string
      t.remove :top_view_colored, type: :string
      t.remove :side_view_colored, type: :string
      t.remove :front_view_colored, type: :string
      t.remove :angled_view_colored, type: :string
      t.remove :brochure, type: :string
      t.remove :holo, type: :string
      t.remove :store_image_width, type: :integer
      t.remove :store_image_height, type: :integer
      t.remove :rsi_store_image_width, type: :integer
      t.remove :rsi_store_image_height, type: :integer
      t.remove :fleetchart_image_width, type: :integer
      t.remove :fleetchart_image_height, type: :integer
      t.remove :top_view_width, type: :integer
      t.remove :top_view_height, type: :integer
      t.remove :side_view_width, type: :integer
      t.remove :side_view_height, type: :integer
      t.remove :front_view_width, type: :integer
      t.remove :front_view_height, type: :integer
      t.remove :angled_view_width, type: :integer
      t.remove :angled_view_height, type: :integer
      t.remove :top_view_colored_width, type: :integer
      t.remove :top_view_colored_height, type: :integer
      t.remove :side_view_colored_width, type: :integer
      t.remove :side_view_colored_height, type: :integer
      t.remove :front_view_colored_width, type: :integer
      t.remove :front_view_colored_height, type: :integer
      t.remove :angled_view_colored_width, type: :integer
      t.remove :angled_view_colored_height, type: :integer
    end

    # ModelPaints — 7 string columns + 14 width/height columns
    change_table :model_paints, bulk: true do |t|
      t.remove :store_image, type: :string
      t.remove :rsi_store_image, type: :string
      t.remove :fleetchart_image, type: :string
      t.remove :top_view, type: :string
      t.remove :side_view, type: :string
      t.remove :angled_view, type: :string
      t.remove :store_image_width, type: :integer
      t.remove :store_image_height, type: :integer
      t.remove :rsi_store_image_width, type: :integer
      t.remove :rsi_store_image_height, type: :integer
      t.remove :fleetchart_image_width, type: :integer
      t.remove :fleetchart_image_height, type: :integer
      t.remove :top_view_width, type: :integer
      t.remove :top_view_height, type: :integer
      t.remove :side_view_width, type: :integer
      t.remove :side_view_height, type: :integer
      t.remove :angled_view_width, type: :integer
      t.remove :angled_view_height, type: :integer
    end

    # ModelModules — 1 string + 2 width/height
    change_table :model_modules, bulk: true do |t|
      t.remove :store_image, type: :string
      t.remove :store_image_width, type: :integer
      t.remove :store_image_height, type: :integer
    end

    # ModelModulePackages — 5 string + 10 width/height
    change_table :model_module_packages, bulk: true do |t|
      t.remove :store_image, type: :string
      t.remove :top_view, type: :string
      t.remove :side_view, type: :string
      t.remove :angled_view, type: :string
      t.remove :store_image_width, type: :integer
      t.remove :store_image_height, type: :integer
      t.remove :top_view_width, type: :integer
      t.remove :top_view_height, type: :integer
      t.remove :side_view_width, type: :integer
      t.remove :side_view_height, type: :integer
      t.remove :angled_view_width, type: :integer
      t.remove :angled_view_height, type: :integer
    end

    # ModelUpgrades — 1 string + 2 width/height
    change_table :model_upgrades, bulk: true do |t|
      t.remove :store_image, type: :string
      t.remove :store_image_width, type: :integer
      t.remove :store_image_height, type: :integer
    end

    # Components — 1 string + 2 width/height
    change_table :components, bulk: true do |t|
      t.remove :store_image, type: :string
      t.remove :store_image_width, type: :integer
      t.remove :store_image_height, type: :integer
    end

    # Manufacturers — 1 string
    remove_column :manufacturers, :logo, :string

    # Users — 1 string
    remove_column :users, :avatar, :string

    # Fleets — 2 strings
    change_table :fleets, bulk: true do |t|
      t.remove :logo, type: :string
      t.remove :background_image, type: :string
    end

    # Images — 1 string + 2 width/height
    change_table :images, bulk: true do |t|
      t.remove :name, type: :string
      t.remove :width, type: :integer
      t.remove :height, type: :integer
    end

    # Imports — 1 string
    remove_column :imports, :import, :string
  end
end
