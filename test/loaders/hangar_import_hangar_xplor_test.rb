# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

class HangarImportHangarXplorTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    load_loader_fixtures
    @user = create(:user)
    @import_file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/imports/hangarXPLOR.json"))
    @import = ::Imports::HangarImport.create!(user_id: @user.id, import: @import_file)
  end

  test "imports all data from hangarXPLOR export" do
    result = ::HangarImporter.new(@import).run
    assert_equal({missing: [], imported: HangarImportFixtures::IMPORTED_SHIPS_HANGAR_XPLOR, success: true}, result)
  end

  # Hangar XPLORer fills `ship_name` from its own ship list unless the owner
  # gave the ship a name, so an unnamed ship arrives carrying its standard
  # name in the field that holds a custom one.
  test "does not take the standard name of an unnamed ship for a custom name" do
    import = import_for([xplor_row(name: "Aurora ES", ship_code: "RSI_Aurora_Mk_I_ES", ship_name: "Aurora Mk I ES")])

    ::HangarImporter.new(import).run

    assert_nil Vehicle.find_by!(user_id: @user.id).name
  end

  test "keeps the name the owner gave the ship" do
    import = import_for([xplor_row(name: "Aurora ES", ship_code: "RSI_Aurora_Mk_I_ES", ship_name: "Bob's Bus")])

    ::HangarImporter.new(import).run

    assert_equal "Bob's Bus", Vehicle.find_by!(user_id: @user.id).name
  end

  # A ship newer than the vendored list still carries its standard name.
  test "does not take a model's own name for a custom name" do
    import = import_for([xplor_row(name: "Avenger Titan", ship_code: "AEGS_Avenger_Titan_Mk_II", ship_name: "Avenger Titan")])

    ::HangarImporter.new(import).run

    assert_nil Vehicle.find_by!(user_id: @user.id).name
  end

  test "does not take a standard name for a custom name on a painted ship" do
    paint = ModelPaint.find_by!(name: "Caterpillar Pirate Edition")
    import = import_for([xplor_row(name: "Caterpillar Pirate Edition", ship_code: "DRAK_Caterpillar_Pirate", ship_name: "Caterpillar Pirate Edition")])

    ::HangarImporter.new(import).run

    vehicle = Vehicle.find_by!(user_id: @user.id)
    assert_equal paint.model_id, vehicle.model_id
    assert_nil vehicle.name
  end

  test "falls back to a custom name beside a standard ship name" do
    import = import_for([xplor_row(name: "Aurora ES", ship_code: "RSI_Aurora_Mk_I_ES", ship_name: "Aurora Mk I ES", custom_name: "Bob's Bus")])

    ::HangarImporter.new(import).run

    assert_equal "Bob's Bus", Vehicle.find_by!(user_id: @user.id).name
  end

  # A Fleetyards export carries `ship_code` and `ship_name` too, but its
  # `ship_name` is always the name the owner chose.
  test "keeps a name from another format that matches a standard name" do
    import = import_for([{name: "Aurora ES", ship_code: "RSI_Aurora_Mk_I_ES", ship_name: "Aurora Mk I ES"}])

    ::HangarImporter.new(import).run

    assert_equal "Aurora Mk I ES", Vehicle.find_by!(user_id: @user.id).name
  end

  # The file the import modal offers as a download. A sample that stops
  # importing is worse than none, so it is imported here rather than trusted.
  test "the published example file imports cleanly" do
    file = Rack::Test::UploadedFile.new(Rails.root.join("public/examples/hangar-xplor-example.json"))
    import = ::Imports::HangarImport.create!(user_id: @user.id, import: file)

    result = ::HangarImporter.new(import).run

    assert_empty result[:missing]
    assert_equal ["325a", "Avenger Titan", "Cutlass Black"], result[:imported]
    assert_predicate Vehicle.where(user_id: @user.id).purchased, :any?
  end

  def xplor_row(**attributes)
    {
      manufacturer_code: "RSI", manufacturer_name: "Roberts Space Industries",
      lti: true, warbond: false, entity_type: "ship",
      pledge_id: "00000001", pledge_name: "Package", pledge_date: "January 1, 2020", pledge_cost: "$45.00 USD"
    }.merge(attributes)
  end

  def import_for(items)
    import = ::Imports::HangarImport.create!(user_id: @user.id, import: @import_file)
    import.update!(import_data: items)
    import
  end
end
