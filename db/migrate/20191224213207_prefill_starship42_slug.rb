class PrefillStarship42Slug < ActiveRecord::Migration[5.2]
  def up
    system("curl -XPUT -H \"Content-Type: application/json\" http://localhost:9200/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'")

    Model.find_each do |model|
      model.update(starship42_slug: model.rsi_name)
    end
  end

  def down
  end
end
