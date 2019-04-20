# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if ENV['TEST_SEEDS'].present?
  require 'rsi_models_loader'

  RsiModelsLoader.new(vat_percent: Rails.application.secrets[:rsi_vat_percent]).all

  model = Model.first
  16.times do |index|
    model.images << Image.new(name: Rails.root.join("db/seeds/images/models/stub-#{index}.jpg").open, enabled: true)
  end

  stanton = Starsystem.find_or_create_by!(name: 'Stanton')
  stanton.update!(map_x: '59.766411599', map_y: '48.460661345', hidden: false)
  crusader = CelestialObject.find_or_create_by!(name: 'Crusader')
  crusader.update!(starsystem: stanton, hidden: false)
  portolisar = Station.find_or_initialize_by(name: 'Port Olisar')
  portolisar.update!(celestial_object: crusader, station_type: :hub, location: 'Orbit', hidden: false)

  test_user = User.find_or_initialize_by(username: 'TestUser')
  test_user.skip_confirmation!
  test_user.update!(
    password: 'TestPassword',
    password_confirmation: 'TestPassword',
    email: 'test@fleetyards.net'
  )

  RoadmapItem.create(
    rsi_id: 1,
    release: '1.0.0',
    release_description: 'lorem ipsum',
    rsi_release_id: 1,
    released: false,
    rsi_category_id: 6,
    name: 'Foo Bar',
    description: 'lorem ipsum',
    body: 'lorem ipsum',
    image: '/media/a71abdkipkp96r/product_thumb_large/01-Pacheco.jpg',
    tasks: 2,
    inprogress: 0,
    completed: 0
  )

  return
end

Dir[File.join(Rails.root, 'db', 'seeds', '**', '*.rb')].sort.each do |seed|
  load seed
end