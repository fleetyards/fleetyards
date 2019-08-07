class PrefillErkulSlugs < ActiveRecord::Migration[5.2]
  def up
    erkul_data = JSON.parse(File.read(Rails.public_path.join('sc_dps_calculator.json')))

    Model.where(production_status: 'flight-ready').find_each do |model|
      slug = erkul_data.select do |item|
        item['ship'] == model.name
      end.map do |item|
        item['url']
      end.first

      next if slug.blank?

      model.update(erkuls_slug: slug.gsub('https://www.erkul.games/calculator/fleetyardsnet/', ''))
    end
  end

  def down
  end
end
