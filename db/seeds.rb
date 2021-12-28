# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

elasticsearch_url = ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'

system("curl -XPUT -H \"Content-Type: application/json\" #{elasticsearch_url}/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'")
puts ''

if ENV['TEST_SEEDS'].present?
  require 'rsi/models_loader'

  ::Rsi::ModelsLoader.new(vat_percent: Rails.configuration.rsi.vat_percent).all

  model = Model.first
  20.times do |index|
    model.images << Image.new(name: Rails.root.join("db/seeds/images/models/stub-#{index}.jpg").open, enabled: true)
  end

  stanton = Starsystem.find_or_create_by!(name: 'Stanton')
  stanton.update!(map_x: '59.766411599', map_y: '48.460661345', hidden: false)
  crusader = CelestialObject.find_or_create_by!(name: 'Crusader')
  crusader.update!(starsystem: stanton, hidden: false)
  portolisar = Station.find_or_initialize_by(name: 'Port Olisar')
  portolisar.update!(celestial_object: crusader, station_type: :station, location: 'Orbit', hidden: false)

  test_user = User.find_or_initialize_by(username: 'TestUser')
  test_user.skip_confirmation!
  test_user.update!(
    password: 'TestPassword',
    password_confirmation: 'TestPassword',
    email: 'test@fleetyards.net'
  )

  RoadmapItem.create(
    rsi_id: 500,
    release: '1.0.0',
    release_description: 'lorem ipsum',
    rsi_release_id: 500,
    released: false,
    rsi_category_id: 6,
    name: 'Foo Bar',
    description: 'lorem ipsum',
    body: 'lorem ipsum',
    image: '/media/a71abdkipkp96r/product_thumb_large/01-Pacheco.jpg',
    tasks: 2,
    inprogress: 0,
    completed: 0,
    active: true
  )

  return
end

if ENV['FLEETCHART_SEEDS'].present?
  CarrierWave.clean_cached_files!

  Dir[File.join(Rails.root, 'db', 'seeds_fleetchart', '*')].sort.select do |file|
    File.directory?(file)
  end.each do |ship_dir|
    slug = File.basename(ship_dir)

    puts "Importing #{slug}..."

    model = Model.find_by(slug: slug)

    next if model.blank?

    side_view = Pathname.new(ship_dir).join('side-fleetchart.png')
    top_view = Pathname.new(ship_dir).join('top-fleetchart.png')
    angled_view = Pathname.new(ship_dir).join('angled-fleetchart.png')
    holo = Pathname.new(ship_dir).join('holo.gltf')
    model.update(
      side_view: (side_view.open if File.exist?(side_view)),
      top_view: (top_view.open if File.exist?(top_view)),
      angled_view: (angled_view.open if File.exist?(angled_view)),
      holo: (holo.open if File.exist?(holo))
    )

    CarrierWave.clean_cached_files!

    puts "#{slug} imported"
  end

  puts "Models missing: #{Model.active.visible.where(top_view: nil).count}"
end

unless ENV['SKIP_SEEDS'].present?
  Dir[File.join(Rails.root, 'db', 'seeds', '**', '*.rb')].sort.each do |seed|
    puts seed.remove("#{Rails.root}/db/seeds/")
    load seed
  end
end
