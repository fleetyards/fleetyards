class AddMetaFieldsForFleetchartUploader < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :fleetchart_image_height, :integer
    add_column :models, :fleetchart_image_width, :integer
    add_column :models, :angled_view_height, :integer
    add_column :models, :angled_view_width, :integer
    add_column :models, :top_view_height, :integer
    add_column :models, :top_view_width, :integer
    add_column :models, :side_view_height, :integer
    add_column :models, :side_view_width, :integer
    add_column :model_paints, :fleetchart_image_height, :integer
    add_column :model_paints, :fleetchart_image_width, :integer
    add_column :model_paints, :angled_view_height, :integer
    add_column :model_paints, :angled_view_width, :integer
    add_column :model_paints, :top_view_height, :integer
    add_column :model_paints, :top_view_width, :integer
    add_column :model_paints, :side_view_height, :integer
    add_column :model_paints, :side_view_width, :integer

    Model.find_each do |model|
      begin
        model.fleetchart_image.cache_stored_file!
        model.fleetchart_image.retrieve_from_cache!(model.fleetchart_image.cache_name)
        model.fleetchart_image.recreate_versions!(:small, :medium, :large, :xlarge)
        model.angled_view.cache_stored_file!
        model.angled_view.retrieve_from_cache!(model.angled_view.cache_name)
        model.angled_view.recreate_versions!(:small, :medium, :large, :xlarge)
        model.top_view.cache_stored_file!
        model.top_view.retrieve_from_cache!(model.top_view.cache_name)
        model.top_view.recreate_versions!(:small, :medium, :large, :xlarge)
        model.side_view.cache_stored_file!
        model.side_view.retrieve_from_cache!(model.side_view.cache_name)
        model.side_view.recreate_versions!(:small, :medium, :large, :xlarge)
        model.save!
      rescue => e
        puts  "ERROR: Model: #{model.id} -> #{e.to_s}"
      end
    end

    CarrierWave.clean_cached_files!

    ModelPaint.find_each do |model|
      begin
        model.fleetchart_image.cache_stored_file!
        model.fleetchart_image.retrieve_from_cache!(model.fleetchart_image.cache_name)
        model.fleetchart_image.recreate_versions!(:small, :medium, :large, :xlarge)
        model.angled_view.cache_stored_file!
        model.angled_view.retrieve_from_cache!(model.angled_view.cache_name)
        model.angled_view.recreate_versions!(:small, :medium, :large, :xlarge)
        model.top_view.cache_stored_file!
        model.top_view.retrieve_from_cache!(model.top_view.cache_name)
        model.top_view.recreate_versions!(:small, :medium, :large, :xlarge)
        model.side_view.cache_stored_file!
        model.side_view.retrieve_from_cache!(model.side_view.cache_name)
        model.side_view.recreate_versions!(:small, :medium, :large, :xlarge)
        model.save!
      rescue => e
        puts  "ERROR: ModelPaint: #{model.id} -> #{e.to_s}"
      end
    end
  end
end
