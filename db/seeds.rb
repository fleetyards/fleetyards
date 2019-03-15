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
  crusader.update!(hidden: false)
  portolisar = Station.find_or_initialize_by(name: 'Port Olisar')
  portolisar.update!(celestial_object: crusader, station_type: :hub, location: 'Orbit', hidden: false)

  test_user = User.find_or_initialize_by(username: 'TestUser')
  test_user.skip_confirmation!
  test_user.update!(
    password: 'TestPassword',
    password_confirmation: 'TestPassword',
    email: 'test@fleetyards.net'
  )

  return
end

Dir[File.join(Rails.root, 'db', 'seeds', '**', '*.rb')].sort.each do |seed|
  load seed
end