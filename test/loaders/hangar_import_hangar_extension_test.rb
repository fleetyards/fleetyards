# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

class HangarImportHangarExtensionTest < ActiveSupport::TestCase
  include HangarImportFixtures

  EXAMPLE_FILE = Rails.root.join("public/examples/hangar-extension-example.json")

  setup do
    load_loader_fixtures
    @user = create(:user)
  end

  # The file the import modal offers as a download. A sample that stops
  # importing is worse than none, so it is imported here rather than trusted.
  test "the published example file imports cleanly" do
    result = ::HangarImporter.new(import_of_example).run

    assert_empty result[:missing]
    assert_includes result[:imported], "Carrack"
    assert_predicate Vehicle.where(user_id: @user.id).purchased, :any?
  end

  # The Carrack creates its Ursa and C8X Pisces itself, as a loaner or a
  # bundled snub craft. Importing the extension's entries for them as well
  # would put each one in the hangar twice.
  test "skips a craft the parent ship already creates" do
    ursa = Model.find_by!(name: "Ursa")
    pisces = Model.find_by!(name: "C8X Pisces Expedition")
    carrack = Model.find_by!(name: "Carrack")
    ModelLoaner.create!(model: carrack, loaner_model: ursa)
    ModelLoaner.create!(model: carrack, loaner_model: pisces)

    result = ::HangarImporter.new(import_of_example).run

    assert_equal ["Avenger Titan", "Carrack", "F7C-M Super Hornet Heartseeker Mk I"], result[:imported]
    assert_empty Vehicle.where(user_id: @user.id, model: [ursa, pisces], loaner: false, bundled: false)
  end

  test "imports an included craft its parent does not create" do
    result = ::HangarImporter.new(import_of_example).run

    assert_equal ["Avenger Titan", "C8X Pisces Expedition", "Carrack", "F7C-M Super Hornet Heartseeker Mk I", "Ursa"],
      result[:imported]
  end

  test "imports an included craft whose parent matched nothing" do
    import = import_for([
      {matrix: "Ursa", name: "Ursa", included_with: "Bengal Carrier"},
      {matrix: "Bengal Carrier", name: "Bengal"}
    ])

    result = ::HangarImporter.new(import).run

    assert_equal ["Ursa"], result[:imported]
    assert_equal ["Bengal Carrier"], result[:missing]
  end

  test "skips the craft of every parent, one per parent" do
    give_the_carrack_an_ursa
    import = import_for([
      {matrix: "Carrack", name: "Carrack"},
      {matrix: "Carrack", name: "Carrack"},
      {matrix: "Ursa", name: "Ursa", included_with: "Carrack"},
      {matrix: "Ursa", name: "Ursa", included_with: "Carrack"}
    ])

    result = ::HangarImporter.new(import).run

    assert_equal ["Carrack", "Carrack"], result[:imported]
  end

  # A rejected parent creates no loaners, so nothing stands in for the craft.
  test "imports the craft of a parent the hangar rejected" do
    give_the_carrack_an_ursa
    Vehicle.create!(user_id: @user.id, model: Model.find_by!(name: "Avenger Titan"), serial: "L8-4261-HA")
    import = import_for([
      {matrix: "Carrack", name: "Carrack", ship_serial: "L8-4261-HA"},
      {matrix: "Ursa", name: "Ursa", included_with: "Carrack"}
    ])

    ::HangarImporter.new(import).run

    assert Vehicle.exists?(user_id: @user.id, model: Model.find_by!(name: "Ursa"), loaner: false, bundled: false)
  end

  test "prefers the matrix name over the export alias" do
    import = import_for([{matrix: "F7C-M Super Hornet Heartseeker Mk I", name: "F7C-M Super Hornet Heartseeker"}])

    result = ::HangarImporter.new(import).run

    assert_equal ["F7C-M Super Hornet Heartseeker Mk I"], result[:imported]
  end

  test "falls back to the export alias when the matrix name matches nothing" do
    import = import_for([{matrix: "Avenger Titan Prototype", name: "Avenger Titan"}])

    result = ::HangarImporter.new(import).run

    assert_equal ["Avenger Titan"], result[:imported]
  end

  test "reports a miss under its matrix name" do
    import = import_for([{matrix: "Bengal Carrier", name: "Bengal"}])

    result = ::HangarImporter.new(import).run

    assert_equal ["Bengal Carrier"], result[:missing]
  end

  def give_the_carrack_an_ursa
    ModelLoaner.create!(model: Model.find_by!(name: "Carrack"), loaner_model: Model.find_by!(name: "Ursa"))
  end

  def import_of_example
    ::Imports::HangarImport.create!(user_id: @user.id, import: Rack::Test::UploadedFile.new(EXAMPLE_FILE))
  end

  def import_for(items)
    import = import_of_example
    import.update!(import_data: items)
    import
  end
end
