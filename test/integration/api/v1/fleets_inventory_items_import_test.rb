# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryItemsImportTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @inventory = create(:fleet_inventory, fleet: @fleet)
  end

  def csv_upload(content)
    file = Tempfile.new(["inventory", ".csv"])
    file.write(content)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  test "imports rows as deposits" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit,notes
        Quantanium,commodity,100,scu,from mining run
        Med Pens,consumable,25,units,
      CSV

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["imported"]
    assert_empty body["errors"]
    assert_equal 2, @inventory.fleet_inventory_items.count
  end

  test "credits the imported entries to the signed in user" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload("name,category,quantity,unit\nQuantanium,commodity,100,scu\n")}

    assert_response :success
    assert_equal [@admin.id], @inventory.fleet_inventory_items.pluck(:added_by)
  end

  test "reports per-row errors without aborting valid rows" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit
        Quantanium,commodity,100,scu
        ,commodity,10,scu
        Titanium,spaceship,10,scu
      CSV

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["imported"]
    assert_equal 2, body["errors"].count
  end

  test "defaults the unit to what the category is measured in" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload(<<~CSV)}
        name,category,quantity
        Quantanium,commodity,100
        FR-66 Shield Generator,component,2
      CSV

    assert_response :success
    assert_equal "scu", @inventory.fleet_inventory_items.find_by(name: "Quantanium").unit
    assert_equal "units", @inventory.fleet_inventory_items.find_by(name: "FR-66 Shield Generator").unit
  end

  test "reports rows whose unit does not fit the category" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload(<<~CSV)}
        name,category,quantity,unit
        FR-66 Shield Generator,component,2,scu
      CSV

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 0, body["imported"]
    assert_includes body["errors"].first["message"], "must be units for component entries"
  end

  test "returns 403 for a member without inventory write access" do
    sign_in @member

    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload("name,quantity\nQuantanium,10\n")}

    assert_response :forbidden
  end

  test "returns 401 when not signed in" do
    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items/import",
      params: {file: csv_upload("name,quantity\nQuantanium,10\n")}

    assert_response :unauthorized
  end
end
