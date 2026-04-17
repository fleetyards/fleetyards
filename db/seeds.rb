# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if ENV["TEST_SEEDS"].present?
  Model.find_or_create_by!(name: "Freelancer") do |model|
    model.hidden = false
    model.manufacturer = Manufacturer.find_or_create_by!(name: "MISC")
  end
  Model.find_or_create_by!(name: "300i") do |model|
    model.hidden = false
    model.manufacturer = Manufacturer.find_or_create_by!(name: "Origin")
  end
  Model.find_or_create_by!(name: "100i") do |model|
    model.hidden = false
    model.manufacturer = Manufacturer.find_or_create_by!(name: "Origin")
  end
  Model.find_or_create_by!(name: "600i Explorer") do |model|
    model.hidden = false
    model.manufacturer = Manufacturer.find_or_create_by!(name: "Origin")
  end
  Model.find_or_create_by!(name: "600i Touring") do |model|
    model.hidden = false
    model.manufacturer = Manufacturer.find_or_create_by!(name: "Origin")
  end

  model = Model.first
  20.times do |index|
    image = Image.new(gallery: model, enabled: true)
    image.file.attach(
      io: Rails.root.join("db/seeds/images/stub.jpg").open,
      filename: "stub-#{index}.jpg",
      content_type: "image/jpeg"
    )
    image.save!
  end

  test_user = User.find_or_initialize_by(username: "TestUser")
  test_user.skip_confirmation!
  test_user.update!(
    password: "TestPassword",
    password_confirmation: "TestPassword",
    email: "test@fleetyards.net"
  )

  freelancer = Model.find_by(name: "Freelancer")
  2.times do |index|
    Vehicle.find_or_create_by!(
      user_id: test_user.id,
      model_id: freelancer.id,
      name: "freelancer-#{index}",
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

  return
end

unless ENV["SKIP_SEEDS"].present?
  Dir[File.join(Rails.root, "db", "seeds", "**", "*.rb")].sort.each do |seed|
    puts seed.remove("#{Rails.root}/db/seeds/")
    load seed
  end
end
