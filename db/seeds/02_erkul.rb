# frozen_string_literal: true

if File.exist?('db/seeds/erkul.json')
  erkul_data = JSON.parse(File.read('db/seeds/erkul.json'))

  erkul_data.each do |erkul_item|
    model = Model.find_by(name: erkul_item['name'])

    next if model.blank?

    slug = erkul_item['url'].split('ship=')[1]
    model.update(erkuls_slug: slug)
  end
end
