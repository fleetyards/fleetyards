# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

elasticsearch_url = ENV["ELASTICSEARCH_URL"] || "http://localhost:9200"

system("curl -XPUT -H \"Content-Type: application/json\" #{elasticsearch_url}/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'")
puts ""

if ENV["TEST_SEEDS"].present?
  require "rsi/models_loader"

  ::Rsi::ModelsLoader.new(vat_percent: Rails.configuration.rsi.vat_percent).all

  model = Model.first
  20.times do |index|
    model.images << Image.new(
      remote_name_url: "https://fleetyards.fra1.digitaloceanspaces.com/seeds/images/models/stub-#{index}.jpg",
      enabled: true
    )
  end

  stanton = Starsystem.find_or_create_by!(name: "Stanton")
  stanton.update!(map_x: "59.766411599", map_y: "48.460661345", hidden: false)
  crusader = CelestialObject.find_or_create_by!(name: "Crusader")
  crusader.update!(starsystem: stanton, hidden: false)
  portolisar = Station.find_or_initialize_by(name: "Port Olisar")
  portolisar.update!(celestial_object: crusader, station_type: :station, location: "Orbit", hidden: false)

  test_user = User.find_or_initialize_by(username: "TestUser")
  test_user.skip_confirmation!
  test_user.update!(
    password: "TestPassword",
    password_confirmation: "TestPassword",
    email: "test@fleetyards.net"
  )

  ["freelancer", "freelancer"].each_with_index do |slug, index|
    Vehicle.find_or_create_by!(
      user_id: test_user.id,
      model_id: Model.find_by(slug: slug).id,
      name: "#{slug}-#{index}",
      wanted: false,
      public: true
    )
  end

  fleet = Fleet.find_or_create_by!(
    name: "TestFleet",
    fid: "TESTFLEET",
    created_by: test_user.id,
    public_fleet: true
  )

  fleet.fleet_memberships.each do |membership|
    membership.setup_fleet_vehicles
  end

  RoadmapItem.create(
    rsi_id: 500,
    release: "1.0.0",
    release_description: "lorem ipsum",
    rsi_release_id: 500,
    released: false,
    rsi_category_id: 6,
    name: "Foo Bar",
    description: "lorem ipsum",
    body: "lorem ipsum",
    image: "/media/a71abdkipkp96r/product_thumb_large/01-Pacheco.jpg",
    tasks: 2,
    inprogress: 0,
    completed: 0,
    active: true
  )

  return
end

if ENV["FLEETCHART_SEEDS"].present?
  CarrierWave.clean_cached_files!

  s3_seeds_fleetcharts_base_url = [
    Rails.configuration.app.s3_endpoint,
    Rails.configuration.app.s3_seeds_fleetchart_bucket
  ].join("/")

  Model.find_each do |model|
    puts "Importing #{model.slug}..."

    model_s3_url = [
      s3_seeds_fleetcharts_base_url,
      model.slug
    ].join("/")

    model.update(remote_side_view_url: "#{model_s3_url}/side-fleetchart.png")
    model.update(remote_top_view_url: "#{model_s3_url}/top-fleetchart.png")
    model.update(remote_angled_view_url: "#{model_s3_url}/angled-fleetchart.png")
    model.update(remote_holo_url: "#{model_s3_url}/holo.gltf")

    CarrierWave.clean_cached_files!

    puts "#{model.slug} imported"
  end

  puts "Models missing: #{Model.active.visible.where(top_view: nil).count}"
end

unless ENV["SKIP_SEEDS"].present?
  Dir[File.join(Rails.root, "db", "seeds", "**", "*.rb")].sort.each do |seed|
    puts seed.remove("#{Rails.root}/db/seeds/")
    load seed
  end
end
